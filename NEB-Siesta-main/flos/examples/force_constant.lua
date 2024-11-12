--[[
Example on how to run a custom force constant run using flos.

This example reads the input options as read by
SIESTA and defines the FC type of run:

 - MD.FCFirst
 - MD.FCLast
 - MD.FCDispl (max-displacement, i.e. for the heaviest atom)

This script will emulate the FC run built-in SIESTA and will only
create the DM file for the first (x0) coordinate.

There are a couple of parameters:

1. same_displ = true|false
 if true all displacements will be true, and the algorithm is equivalent
 to the SIESTA FC run.
 If false, the displacements are dependent on the relative masses of the
 atomic species. The given displacement is then the maximum displacement, 
 i.e. the displacement on the heaviest atom.
2. displ = {}
 a list of different displacements. If one is interested in several different
 force constant runs with different displacements, this is a simple way
 to do it all at once.

--]]

-- Set this flag to false if the displacements should be
-- different for atoms with different masses.
local same_displ = true

-- In case you want to run several FC runs using different
-- displacements in a single run you may use this list.
local displ = {0.005, 0.01, 0.02, 0.03, 0.04}
-- To get the displacement from SIESTA, uncomment the following line.
-- local displ = nil



-- Everything below this point should not be touched.

-- Load the FLOS module
local flos = require "flos"

-- Starting displacement
local idispl = 1

-- Create placeholder for the FC object
-- This will be allocated in the initialization routine
local FC = nil

-- Grab the unit table of siesta (it is already created
-- by SIESTA)
local Unit = siesta.Units


function siesta_comm()
   
   -- This routine does exchange of data with SIESTA
   local ret_tbl = {}

   -- Do the actual communication with SIESTA
   if siesta.state == siesta.INITIALIZE then
      
      -- In the initialization step we request the
      -- convergence criteria
      --  MD.FCFirst
      --  MD.FCLast
      --  MD.FCDispl
      siesta.receive({"geom.xa",
		      "geom.mass",
		      "MD.FC.Displ",
		      "MD.FC.First",
		      "MD.FC.Last"})

      -- Print information
      IOprint("\nLUA Using the FC run")

      if displ == nil then
	 -- Specify the displacement if the user requests
	 -- the information from SIESTA
	 displ = { siesta.MD.FC.Displ / Unit.Ang }
      end

      -- Get coordinates in Ang
      local xa = flos.Array.from(siesta.geom.xa) / Unit.Ang

      indices = flos.Array.range(siesta.MD.FC.First, siesta.MD.FC.Last)
      if same_displ then
	 -- No masses, all equal (implicitly)
	 FC = flos.ForceHessian(xa, indices, displ[idispl])
      else
	 -- Masses used
	 FC = flos.ForceHessian(xa, indices, displ[idispl],
				siesta.geom.mass)
      end
      
   end

   if siesta.state == siesta.MOVE then
      
      -- We retrieve the current coordinates, the forces
      -- and whether the geometry has relaxed
      siesta.receive({"geom.xa",
		      "geom.fa",
		      "Write.DM",
		      "Write.EndOfCycle.DM",
		      "MD.Relaxed"})

      ret_tbl = siesta_move(siesta)

      -- Disable writing the DM after the initial DM creation
      -- (forces the reuse of the xa0 DM)
      siesta.Write.DM = false
      ret_tbl[#ret_tbl+1] = "Write.DM"
      siesta.Write.EndOfCycle.DM = false
      ret_tbl[#ret_tbl+1] = "Write.EndOfCycle.DM"

      -- write to the FC file (this will get updated periodically to
      -- track information).
      -- The files also contain the displacements.
      FC:save( ("FLOS.FC.%d"):format(idispl) )
      FC:save( ("FLOS.FCSYM.%d"):format(idispl), true )

      if siesta.MD.Relaxed then
	 -- Check that we should move to the next displacement
	 -- iteration
	 idispl = idispl + 1

	 if idispl <= #displ then
	    
	    -- Reset counters for the next FC run with
	    -- different displacement
	    FC:reset()
	    -- Update new displacement
	    FC:set_displacement(displ[idispl])
	    
	    -- Set for the next displacement (no need
	    -- to re-calculate the initial forces)
	    siesta.geom.xa = FC:next() * Unit.Ang
	    siesta.MD.Relaxed = false

	 end

      end

   end

   siesta.send(ret_tbl)
end

function siesta_move(siesta)

   local fa = flos.Array.from(siesta.geom.fa) * Unit.Ang / Unit.eV

   -- Send back new coordinates (convert to Bohr)
   siesta.geom.xa = FC:next(fa) * Unit.Ang
   siesta.MD.Relaxed = FC:done()
   
   return {"geom.xa",
	   "MD.Relaxed"}
end
