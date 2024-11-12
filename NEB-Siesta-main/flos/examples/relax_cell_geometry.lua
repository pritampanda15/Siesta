--[[
Example on how to relax lattice vectors using the LBFGS 
algorithm.

This example can take any geometry and will relax the 
cell vectors according to the siesta input options:

 - MD.MaxForceTol
 - MD.MaxStressTol
 - MD.MaxCGDispl

This example is prepared to easily create
a combined relaxation of several LBFGS algorithms
simultaneously. In some cases this is shown to
speed up the convergence because an average is taken
over several optimizations.

To converge using several LBFGS algorithms simultaneously
may be understood phenomenologically by a "line-search" 
optimization by weighing two Hessian optimizations.

This example defaults to two simultaneous LBFGS algorithms
which seems adequate in most situations.

--]]

-- Load the FLOS module
local flos = require "flos"

-- Create the two LBFGS algorithms with
-- initial Hessians 1/75 and 1/50
local geom = {}
geom[1] = flos.LBFGS{H0 = 1. / 75.}
geom[2] = flos.LBFGS{H0 = 1. / 50.}

local lattice = {}
lattice[1] = flos.LBFGS{H0 = 1. / 75.}
lattice[2] = flos.LBFGS{H0 = 1. / 50.}

-- Grab the unit table of siesta (it is already created
-- by SIESTA)
local Unit = siesta.Units

-- Initial strain that we want to optimize to minimize
-- the stress.
local strain = flos.Array.zeros(6)
-- Mask which directions we should relax
--   [xx, yy, zz, yz, xz, xy]
-- Default to all.
local stress_mask = flos.Array.ones(6)

-- To only relax the diagonal elements you may do this:
stress_mask[4] = 0.
stress_mask[5] = 0.
stress_mask[6] = 0.

-- The initial cell
local cell_first

-- This variable controls which relaxation is performed
-- first.
-- If true, it starts by relaxing the geometry (coordinates)
--    (recommended)
-- If false, it starts by relaxing the cell vectors.
local relax_geom = true

function siesta_comm()
   
   -- This routine does exchange of data with SIESTA
   local ret_tbl = {}

   -- Do the actual communication with SIESTA
   if siesta.state == siesta.INITIALIZE then
      
      -- In the initialization step we request the
      -- convergence criteria
      --  MD.MaxDispl
      --  MD.MaxStressTol
      siesta.receive({"geom.cell",
		      "MD.Relax.Cell",
		      "MD.MaxDispl",
		      "MD.MaxForceTol",
		      "MD.MaxStressTol"})

      -- Check that we are allowed to change the cell parameters
      if not siesta.MD.Relax.Cell then

	 -- We force SIESTA to relax the cell vectors
	 siesta.MD.Relax.Cell = true
	 ret_tbl = {"MD.Relax.Cell"}

      end

      -- Print information
      IOprint("\nLUA convergence information for the LBFGS algorithms:")

      -- Store the initial cell (global variable)
      cell_first = flos.Array.from(siesta.geom.cell) / Unit.Ang

      -- Ensure we update the convergence criteria
      -- from SIESTA (in this way one can ensure siesta options)
      IOprint("Lattice optimization:")
      for i = 1, #lattice do
	 lattice[i].tolerance = siesta.MD.MaxStressTol * Unit.Ang ^ 3 / Unit.eV
	 lattice[i].max_dF = siesta.MD.MaxDispl / Unit.Ang

	 -- Print information
	 if siesta.IONode then
	    lattice[i]:info()
	 end
      end

      IOprint("\nGeometry optimization:")
      for i = 1, #geom do
	 geom[i].tolerance = siesta.MD.MaxForceTol * Unit.Ang / Unit.eV
	 geom[i].max_dF = siesta.MD.MaxDispl / Unit.Ang
	 
	 -- Print information
	 if siesta.IONode then
	    geom[i]:info()
	 end
      end

      if relax_geom then
	 IOprint("\nLUA: Starting with geometry relaxation!\n")
      else
	 IOprint("\nLUA: Starting with cell relaxation!\n")
      end
      
   end

   if siesta.state == siesta.MOVE then

      -- Regardless of the method we
      -- retrieve everything so that we
      -- can check if both are converged
      siesta.receive({"geom.cell",
		      "geom.xa",
		      "geom.fa",
		      "geom.stress",
		      "MD.Relaxed"})
      ret_tbl = siesta_move(siesta)
   end

   siesta.send(ret_tbl)
end

function siesta_move(siesta)
   -- Dispatcher function for doing both geometry and lattice
   -- relaxation.

   -- Internally convert the siesta quantities
   -- to their correct physical values
   siesta.geom.cell = flos.Array.from(siesta.geom.cell) / Unit.Ang
   siesta.geom.xa = flos.Array.from(siesta.geom.xa) / Unit.Ang
   siesta.geom.fa = flos.Array.from(siesta.geom.fa) * Unit.Ang / Unit.eV
   -- The stress is the negative gradient
   siesta.geom.stress = -flos.Array.from(siesta.geom.stress) * Unit.Ang ^ 3 / Unit.eV


   -- Grab whether both methods have converged
   local voigt = stress_to_voigt(siesta.geom.stress)
   voigt = voigt * stress_mask
   local conv_lattice = lattice[1]:optimized(voigt)
   voigt = nil
   
   local conv_geom = geom[1]:optimized(siesta.geom.fa)

   -- Immediately return if both have converged
   if conv_lattice and conv_geom then
      
      siesta.MD.Relaxed = true
      return {'MD.Relaxed'}
      
   end

   -- We have not converged
   -- Figure out if we should switch algorithm
   if relax_geom and conv_geom then
      
      relax_geom = false
      -- Ensure that we reset the geometry relaxation
      for i = 1, #geom do
	 geom[i]:reset()
      end

      -- Update the initial cell as the algorithm
      -- has started from a fresh (it is already
      -- in correct units).
      cell_first = siesta.geom.cell:copy()
      -- Also initialize the initial strain
      strain = flos.Array.zeros(6)

      IOprint("\nLUA: switching to cell relaxation!\n")
      
   elseif (not relax_geom) and conv_lattice then
      
      relax_geom = true
      -- Ensure that we reset the geometry relaxation
      for i = 1, #lattice do
	 lattice[i]:reset()
      end

      IOprint("\nLUA: switching to geometry relaxation!\n")

   end

   -- Now perform the optimization of the method
   -- we currently use
   if relax_geom then
      return siesta_geometry(siesta)
   else
      return siesta_cell(siesta)
   end

end


function stress_to_voigt(stress)
   -- Retrieve the stress
   local voigt = flos.Array.empty(6)

   -- Copy over the stress to the Voigt representation
   voigt[1] = stress[1][1]
   voigt[2] = stress[2][2]
   voigt[3] = stress[3][3]
   -- ... symmetrize stress tensor
   voigt[4] = (stress[2][3] + stress[3][2]) * 0.5
   voigt[5] = (stress[1][3] + stress[3][1]) * 0.5
   voigt[6] = (stress[1][2] + stress[2][1]) * 0.5

   return voigt
end

function stress_from_voigt(voigt)
   local stress = flos.Array.empty(3, 3)

   -- Copy over the stress from Voigt representation
   stress[1][1] = voigt[1]
   stress[1][2] = voigt[6]
   stress[1][3] = voigt[5]
   stress[2][1] = voigt[6]
   stress[2][2] = voigt[2]
   stress[2][3] = voigt[4]
   stress[3][1] = voigt[5]
   stress[3][2] = voigt[4]
   stress[3][3] = voigt[3]

   return stress
end


function siesta_geometry(siesta)

   -- Retrieve the atomic coordinates and the forces
   local xa = siesta.geom.xa
   -- Note the LBFGS requires the gradient, and
   -- the force is the negative gradient.
   local fa = siesta.geom.fa

   -- Perform step (initialize arrays to do averaging if more
   -- LBFGS algorithms are in use).
   local all_xa = {}
   local weight = flos.Array.empty(#geom)
   for i = 1, #geom do
      
      -- Calculate the next optimized structure (that
      -- minimizes the Hessian)
      all_xa[i] = geom[i]:optimize(xa, fa)
      
      -- Get the optimization length for calculating
      -- the best average.
      weight[i] = geom[i].weight
      
   end

   -- Normalize weight
   weight = weight / weight:sum()
   if #geom > 1 then
      IOprint("\nGeometry weighted average: ", weight)
   end

   -- Calculate the new coordinates and figure out
   -- if the algorithms has been optimized.
   local out_xa = all_xa[1] * weight[1]
   for i = 2, #geom do
      out_xa = out_xa + all_xa[i] * weight[i]
   end
   -- Immediately clean-up to reduce memory overhead (force GC)
   all_xa = nil

   -- Send back new coordinates (convert to Bohr)
   siesta.geom.xa = out_xa * Unit.Ang
   
   return {"geom.xa"}
end


function siesta_cell(siesta)

   -- Get the current cell
   local cell = siesta.geom.cell
   -- Retrieve the atomic coordinates
   local xa = siesta.geom.xa
   -- Retrieve the stress
   local stress = stress_to_voigt(siesta.geom.stress)
   stress = stress * stress_mask
   
   -- Calculate the volume of the cell to normalize the stress
   local vol = cell[1]:cross(cell[2]):dot(cell[3])
   
   -- Perform step (initialize arrays to do averaging if more
   -- LBFGS algorithms are in use).
   local all_strain = {}
   local weight = flos.Array.empty(#lattice)
   for i = 1, #lattice do
      
      -- Calculate the next optimized cell structure (that
      -- minimizes the Hessian)
      -- The optimization routine requires the stress to be per cell
      all_strain[i] = lattice[i]:optimize(strain, stress * vol)

      -- The LBFGS algorithms updates the internal optimized
      -- variable based on stress * vol (eV / cell)
      -- However, we are relaxing the stress in (eV / Ang^3)
      -- So force the optimization to be estimated on the
      -- correct units.
      -- Secondly, the stress optimization is per element
      -- so we need to flatten the stress
      lattice[i]:optimized(stress)
      
      -- Get the optimization length for calculating
      -- the best average.
      weight[i] = lattice[i].weight
      
   end

   -- Normalize weight
   weight = weight / weight:sum()
   if #lattice > 1 then
      IOprint("\nLattice weighted average: ", weight)
   end

   -- Calculate the new optimized strain that should
   -- be applied to the cell vectors to minimize the stress.
   -- Also track if we have converged (stress < min-stress)
   local out_strain = all_strain[1] * weight[1]
   for i = 2, #lattice do
      out_strain = out_strain + all_strain[i] * weight[i]
   end
   -- Immediately clean-up to reduce memory overhead (force GC)
   all_strain = nil

   -- Apply mask to ensure only relaxation of cell-vectors
   -- along wanted directions.
   strain = out_strain * stress_mask
   out_strain = nil

   -- Calculate the new cell
   -- Note that we add one in the diagonal
   -- to create the summed cell
   local dcell = flos.Array( cell.shape )
   dcell[1][1] = 1.0 + strain[1]
   dcell[1][2] = 0.5 * strain[6]
   dcell[1][3] = 0.5 * strain[5]
   dcell[2][1] = 0.5 * strain[6]
   dcell[2][2] = 1.0 + strain[2]
   dcell[2][3] = 0.5 * strain[4]
   dcell[3][1] = 0.5 * strain[5]
   dcell[3][2] = 0.5 * strain[4]
   dcell[3][3] = 1.0 + strain[3]

   -- Create the new cell...
   -- As the strain is a continuously updated value
   -- we need to retain the original cell (done
   -- above in the siesta.INITIALIZE step).
   local out_cell = cell_first:dot(dcell)
   dcell = nil
   
   -- Calculate the new scaled coordinates
   -- First get the fractional coordinates in the
   -- previous cell.
   local lat = flos.Lattice:new(cell)
   local fxa = lat:fractional(xa)
   -- Then convert the coordinates to the
   -- new cell coordinates by simple scaling.
   xa = fxa:dot(out_cell)
   lat = nil
   fxa = nil
   
   -- Send back new coordinates (convert to Bohr)
   siesta.geom.cell = out_cell * Unit.Ang
   siesta.geom.xa = xa * Unit.Ang
   
   return {"geom.cell",
	   "geom.xa"}
end
