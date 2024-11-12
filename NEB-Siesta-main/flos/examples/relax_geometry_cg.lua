--[[
Example on how to relax a geometry using the CG 
algorithm.

This example can take any geometry and will relax it
according to the siesta input options:

 - MD.MaxForceTol
 - MD.MaxCGDispl

One should note that the CG algorithm first converges
when the total force (norm) on the atoms are below the 
tolerance. This is contrary to the SIESTA default which
is a force tolerance for the individual directions,
i.e. max-direction force.

This example is prepared to easily create
a combined relaxation of several CG algorithms
simultaneously. In some cases this is shown to
speed up the convergence because an average is taken
over several optimizations.

This example defaults to two simultaneous CG algorithms
which seems adequate in most situations.

--]]

-- Load the FLOS module
local flos = require "flos"

-- Create the two CG algorithms with
-- initial Hessians 1/75 and 1/50
local CG = {}
CG[1] = flos.CG{beta='PR', line=flos.Line{optimizer = flos.LBFGS{H0 = 1. / 75.} } }
CG[2] = flos.CG{beta='PR', line=flos.Line{optimizer = flos.LBFGS{H0 = 1. / 50.} } }
-- To use more simultaneously simply add a
-- new line... with a separate CG algorithm.

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
      --  MD.MaxDispl
      --  MD.MaxForceTol
      siesta.receive({"MD.MaxDispl",
		      "MD.MaxForceTol"})


      -- Print information
      IOprint("\nLUA convergence information for the LBFGS algorithms:")

      -- Ensure we update the convergence criteria
      -- from SIESTA (in this way one can ensure siesta options)
      for i = 1, #CG do
	 
	 CG[i].tolerance = siesta.MD.MaxForceTol * Unit.Ang / Unit.eV
	 CG[i].max_dF = siesta.MD.MaxDispl / Unit.Ang
	 -- Propagate the tolerances down to the line-search for reducing
	 -- amount of line-searches
	 CG[i].line.tolerance = CG[i].tolerance
	 CG[i].line.max_dF = CG[i].max_dF -- this is not used
	 CG[i].line.optimizer.tolerance = CG[i].tolerance -- this is not used
	 CG[i].line.optimizer.max_dF = CG[i].max_dF -- this is used

	 -- Print information
	 if siesta.IONode then
	    CG[i]:info()
	 end
      end

   end

   if siesta.state == siesta.MOVE then
      
      -- Here we are doing the actual CG algorithm.
      -- We retrieve the current coordinates, the forces
      -- and whether the geometry has relaxed
      siesta.receive({"geom.xa",
		      "geom.fa",
		      "MD.Relaxed"})
      ret_tbl = siesta_move(siesta)
      
   end

   siesta.send(ret_tbl)
end

function siesta_move(siesta)

   -- Retrieve the atomic coordinates and the forces
   local xa = flos.Array.from(siesta.geom.xa) / Unit.Ang
   local fa = flos.Array.from(siesta.geom.fa) * Unit.Ang / Unit.eV

   -- Perform step (initialize arrays to do averaging if more
   -- CG algorithms are in use).
   local all_xa = {}
   local weight = flos.Array.empty(#CG)
   for i = 1, #CG do
      
      -- Calculate the next optimized structure (that
      -- minimizes the Hessian)
      all_xa[i] = CG[i]:optimize(xa, fa)
      
      -- Get the optimization length for calculating
      -- the best average.
      weight[i] = CG[i].weight
      
   end

   -- Normalize weights
   weight = weight / weight:sum()
   if #CG > 1 then
      IOprint("\nCG weighted average: ", weight)
   end

   -- Calculate the new coordinates and figure out
   -- if the algorithms has been optimized.
   local out_xa = all_xa[1] * weight[1]
   local relaxed = CG[1]:optimized()
   for i = 2, #CG do
      
      out_xa = out_xa + all_xa[i] * weight[i]
      relaxed = relaxed and CG[i]:optimized()

   end
   -- Immediately clean-up to reduce memory overhead (force GC)
   all_xa = nil

   -- Send back new coordinates (convert to Bohr)
   siesta.geom.xa = out_xa * Unit.Ang
   siesta.MD.Relaxed = relaxed
   
   return {"geom.xa",
	   "MD.Relaxed"}
end
