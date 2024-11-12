---
-- Implementation of a line minimizer algorithm
-- @classmod Line
-- The `Line` class optimizes a set of parameters for a function
-- such that the gradient projected onto a gradient-direction will be minimized.
-- I.e. it finds the minimum of a function on a gradient line such that the
-- _true_ gradient is orthogonal to the direction.
--
-- A simple implementation of a line minimizer.
-- This line-minimization algorithm may use any (default to `LBFGS`)
-- optimizer and will optimize a given direction by projecting the
-- gradient onto an initial gradient direction.
--
-- @usage
-- line0 = Line()
-- -- The default direction will be the gradient passed for in the
-- -- first `optimize` call.
-- line0:optimize(F, G)
--
-- line1 = Line{optimizer = flos.LBFGS{}}
-- -- This is equivalent to the above case, but we explicitly define
-- -- the minimization direction, and the optimizer.
-- line1:set_direction(F, G)
-- line1:optimize(F, G)


local m = require "math"
local mc = require "flos.middleclass.middleclass"

local optim = require "flos.optima.base"
local LBFGS = require "flos.optima.lbfgs"

-- Create the line search class (inheriting the Optimizer construct)
local Line = mc.class("Line", optim.Optimizer)

--- Instantiating a new `Line` object
--
-- The parameters _must_ be specified with a table of fields and values.
-- In addition to the parameters indicated.
--
-- @see LBFGS
--
-- @usage
-- Line{<field1 = value>, <field2 = value>}
--
-- @function Line:new
-- @Array[opt] direction the line direction (defaults to the first optimization gradient that `Line` gets called with)
-- @Optimizer[opt=`LBFGS`] optimizer the optimization method used to minimize along the direction (defaults to the `LBFGS` optimizer)
local function doc_function()
end


function Line:initialize(tbl)
   -- Initialize from generic optimizer
   optim.Optimizer.initialize(self)

   local tbl = tbl or {}

   -- The initial direction of the line-search
   self.direction = nil

   -- The alpha that minimizes the direction
   self.alpha = 1.

   -- Initialize method to check
   self.optimizer = nil

   -- Ensure we update the elements as passed
   -- by new(...)
   if type(tbl) == "table" then
      for k, v in pairs(tbl) do
	 self[k] = v
      end
   end
   
   if self.optimizer == nil then
      -- The optimization method
      self.optimizer = LBFGS{ tolerance = self.tolerance,
			      max_dF = self.max_dF}
   end

end


--- Define the gradient direction we should minimize, with the accompanying initial
-- parameters.
-- @Array F the initial parameters
-- @Array G the direction to be sampled
function Line:set_direction(F, G)
   self.initial = F:copy()
   self.direction = G:copy()
   self.alpha = 0.
end

--- Reset the Line algorithm by resetting the direction
function Line:reset()
   optim.Optimizer.reset(self)
   self.direction = nil
   self.initial = nil
   self.alpha = 1.
   self.optimizer:reset()
end


--- Query whether the line minimization method has been optimized
-- The input gradient will be projected onto the direction before
-- the optimization will be checked.
-- @Array[opt] G input gradient
-- @return whether the line minimization has been minimized
function Line:optimized(G)
   
   -- determine if the projected gradient has been optimized
   if G == nil then
      return optim.Optimizer.optimized(self)
   else
      return optim.Optimizer.optimized(self, self:projection(G))
   end

end


--- Calculates the next parameter set such that the gradient is minimized
-- along the direction.
--
-- If the internal gradient direction has not been initialized the first
-- gradient will be chosen as the direction, @see set_direction.
-- @Array F input parameters for the function
-- @Array G gradient for the function with the parameters `F`
-- @return a new set of optimized coordinates
function Line:optimize(F, G)

   -- Create initial direction
   if self.direction == nil then

      self:set_direction(F, G)
      
   end

   -- Calculate the new variables given the constraint on the projected vector
   local new = self.optimizer:optimize(F, self:projection(G))
   
   -- Before we return the new coordinates we need to update the alpha parameter
   self.alpha = (new - self.initial):scalar_project(self.direction)

   self.niter = self.niter + 1
   
   return new

end


--- Return a gradient projected onto the internal specified direction
-- @Array G the input gradient
-- @return `G` projected onto the internal gradient direction
function Line:projection(G)
   return G:project(self.direction)
end


--- SIESTA function for performing a complete SIESTA line optimization.
--
-- This function will query these fdf-flags from SIESTA:
--
--  - MD.MaxForceTol
--  - MD.MaxCGDispl
--
-- and use those as the tolerance for convergence as well as the
-- maximum displacement for each optimization step.
--
-- Everything else is controlled by the `Line` object.
--
-- Note that all internal operations in this function relies on units being in
--  - Ang
--  - eV
--  - eV/Ang
--
-- @tparam table siesta the SIESTA global table.
function Line:SIESTA(siesta)

   -- Retrieve the siesta units
   local unit = siesta.Units

   if siesta.state == siesta.INITIALIZE then

      -- Setup the convergence criteria
      siesta.receive({"MD.MaxDispl",
		      "MD.MaxForceTol"})
      
      self.tolerance = siesta.MD.MaxForceTol * unit.Ang / unit.eV
      self.max_dF = siesta.MD.MaxDispl / unit.Ang
      self.optimizer.tolerance = siesta.MD.MaxForceTol * unit.Ang / unit.eV
      self.optimizer.max_dF = siesta.MD.MaxDispl / unit.Ang

      if siesta.IONode then
	 self:info()
      end

   elseif siesta.state == siesta.MOVE then
      
      -- Receive information
      siesta.receive({"geom.xa", "geom.fa", "MD.Relaxed"})

      -- Now retrieve the coordinates and the forces
      local xa = num.Array.from(siesta.geom.xa) / unit.Ang
      local fa = num.Array.from(siesta.geom.fa) * unit.Ang / unit.eV

      -- Only in case that the forces are optimized will we move atoms.
      if self:optimized(fa) then
	 siesta.MD.Relaxed = true
	 siesta.send({"MD.Relaxed"})
      else
	 -- Send back new coordinates (convert to Bohr)
	 siesta.geom.xa = self:optimize(xa, fa) * unit.Ang
	 siesta.send({"geom.xa"})
      end

   end

end

--- Print information regarding the Line algorithm
function Line:info()
   
   print("")
   print("Line: line search:")
   print("Line: iterations " .. tostring(self:iteration()))
   self.optimizer:info()
   print("")

end

return Line
