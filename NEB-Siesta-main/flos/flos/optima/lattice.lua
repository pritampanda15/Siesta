--[[ 
This module implements a class for performing 
lattice optimizations based on scaling the atomic
coordinates and the cell-vectors.
--]]

local m = require "math"
local mc = require "flos.middleclass.middleclass"

local num = require "flos.num"
local optim = require "flos.optima.base"

-- Create the LBFGS class (inheriting the Optimizer construct)
local Lattice = mc.class("Lattice", optim.Optimizer)

function Lattice:initialize(cell, delta, N)
   -- Create the Lattice class which requires
   -- these arguments:
   --  1. cell, the lattice vectors in a 3x3 matrix that are
   --     the initial position.
   --  2. the displacement per itteration.
   --     This may be one of:
   --      a) value, length increase for all cell-directions
   --      b) Array1D, length increase for each cell-direction
   --      c) Array2D, addition to the cell
   --     It defaults to 0.01 Ang
   --  3. N, number of steps that should be taken before
   --     the lattice-optimization ends.
   --     This value defaults to -5.
   --     If this is positive it is the number of displacements
   --     that are performed.
   --     If this is negative it is the number of points
   --     that will be calculated _after_ a minimum
   --     has been found.
   
   -- Current cell coordinates
   self.cell = cell:copy()
   self:update_reciprocal()

   -- The displacement
   self.delta = delta or 0.01

   -- The number of steps to take, and current iteration
   self.N = N or -5
   self.itt = 1

   -- Placeholder for the displacement values and
   -- energies you want to minimize
   self.E = num.Array.empty(1)
   
end


-- Update the internal reciprocal lattice (without 2Pi)
function Lattice:update_reciprocal()

   self.rcell = num.Array.empty(3, 3)
   local c = self.cell
   self.rcell[1][1] = c[2][2]*c[3][3] - c[2][3]*c[3][2]
   self.rcell[1][2] = c[2][3]*c[3][1] - c[2][1]*c[3][3]
   self.rcell[1][3] = c[2][1]*c[3][2] - c[2][2]*c[3][1]
   self.rcell[2][1] = c[3][2]*c[1][3] - c[3][3]*c[1][2]
   self.rcell[2][2] = c[3][3]*c[1][1] - c[3][1]*c[1][3]
   self.rcell[2][3] = c[3][1]*c[1][2] - c[3][2]*c[1][1]
   self.rcell[3][1] = c[1][2]*c[2][3] - c[1][3]*c[2][2]
   self.rcell[3][2] = c[1][3]*c[2][1] - c[1][1]*c[2][3]
   self.rcell[3][3] = c[1][1]*c[2][2] - c[1][2]*c[2][1]

   for i = 1, 3 do
      self.rcell[i] = self.rcell[i] / c[i]:dot(self.rcell[i])
   end

end

-- After having calculated the energy it should
-- be added to the lattice-optimization routine
-- to collect a table.
function Lattice:add_energy(E)
   if #self.E < self.itt then
      self.E.shape[1] = self.E.shape[1] + 1
   end
   self.E[self.itt] = E
end

-- Return the fractional coordinates
function Lattice:fractional(xa)
   return xa:dot(self.rcell ^ "T")
end

function Lattice:next()

   -- Calculate the following lattice
   local cell = self.cell:copy()

   if not num.isArray(self.delta) then
      -- Length addition same
      local ncell = cell:norm()
      for i = 1 , 3 do
	 for j = 1 , 3 do
	    cell[i][j] = cell[i][j] + cell[i][j] / ncell[i] * self.delta
	 end
      end

   elseif #self.delta.shape == 1 then
      -- Length addition individual
      local ncell = cell:norm()
      for i = 1 , 3 do
	 for j = 1, 3 do
	    cell[i][j] = cell[i][j] + cell[i][j] / ncell[i] * self.delta[i]
	 end
      end

   elseif #self.delta.shape == 2 then
      -- simple addition
      cell = cell + self.delta
      
   end

   -- Update the internal cell
   self.cell = cell:copy()
   self.itt = self.itt + 1
   
   return cell
end

return Lattice
