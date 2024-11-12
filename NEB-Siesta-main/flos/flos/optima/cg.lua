---
-- Implementation of the Conjugate Gradient algorithm
-- @classmod CG
-- An implementation of the conjugate gradient optimization
-- algorithm.
-- This class implements 4 different variations of CG defined
-- by the _so-called_ beta-parameter:
--
--  1. Polak-Ribiere
--  2. Fletcher-Reeves
--  3. Hestenes-Stiefel
--  4. Dai-Yuan
--
-- Additionally this CG implementation defaults to a beta-damping
-- factor to achieve a _smooth_ restart method, instead of
-- abrupt CG restarts when `beta < 0`, for instance.

local m = require "math"
local mc = require "flos.middleclass.middleclass"

local num = require "flos.num"
local optim = require "flos.optima.base"
local Line = require "flos.optima.line"
local LBFGS = require "flos.optima.lbfgs"

-- Create the CG class (inheriting the Optimizer construct)
local CG = mc.class("CG", optim.Optimizer)

--- Instantiating a new `CG` object
--
-- The parameters _must_ be specified with a table of named arguments
--
-- The `CG` optimizer implements several variations of the algorithms:
-- The beta-parameter calculation may be performed using either (`beta` field in argument table):
--
--  - Polak-Ribiere [`PR`] (default)
--  - Fletcher-Reeves [`FR`]
--  - Hestenes-Stiefel [`HS`]
--  - Dai-Yuan [`DY`]
--
-- CG algorithms also implements a restart method based on different criteria
-- in this algorithm there is a default smooth restart by damping the `beta`
-- parameter (default to `0.8`). In addition to this there are schemes for
-- explicit restart (`restart` field in argument table):
--
--  - `negative`, when `beta < 0`, CG restarts the conjugate gradient
--  - `Powell`, when the scalar-projection of the two previous gradients is above 0.2
--  
-- @usage
-- cg = CG{<field1 = value>, <field2 = value>}
-- while not cg:optimized() do
--    F = cg:optimize(F, G)
-- end
--
-- @function CG:new
-- @string[opt="PR"] beta determine the method used for `beta`-parameter calculation
-- @number[opt=0.8] beta_damping a factor for the `beta` variable such that a smooth restart is obtained
-- @string[opt="Powell"] restart method of restart
-- @Optimizer[opt] optimizer the optimization method used to minimize along the direction (defaults to the `LBFGS` optimizer)
-- @param ... any arguments `Optimizer:new` accepts
local function doc_function()
end

function CG:initialize(tbl)
   -- Initialize from generic optimizer
   optim.Optimizer.initialize(self)

   local tbl = tbl or {}

   -- Storing the previous steepest descent direction
   -- and the previous gradient
   self.G0 = nil -- the previous gradient
   self.G = nil -- the current gradient
   self.conj0 = nil -- the previous conjugate direction
   self.conj = nil -- the current conjugate direction

   -- Default line search

   -- Weight, currently not used, this is equivalent
   -- weight for all CG methods
   self.weight = 1.

   -- Method of calculating the beta constant
   self.beta = "PR"
   -- Damping factor for creating a smooth CG restart
   -- minimizing beta
   self.beta_damping = 0.8
      
   -- The restart method, currently this may be:
   --   negative (restarting when beta < 0)
   --   Powell (restart when orthogonality is low)
   self.restart = "Powell"

   -- Ensure we update the elements as passed
   -- by new(...)
   if type(tbl) == "table" then
      for k, v in pairs(tbl) do
	 self[k] = v
      end
   end

   if self.line == nil then
      self.line = Line:new({tolerance = self.tolerance,
			    max_dF = self.max_dF})
   end
   
   self:_correct()
end

--- Internal routine for correcting the passed options
-- @local
function CG:_correct()

   -- Check beta method
   local beta = self.beta:lower()
   if beta == "pr" or beta == "p-r" or beta == "polak-ribiere" then
      self.beta = "PR"
   elseif beta == "fr" or beta == "f-r" or beta == "fletcher-reeves" then
      self.beta = "FR"
   elseif beta == "hs" or beta == "h-s" or beta == "hestenes-stiefel" then
      self.beta = "HS"
   elseif beta == "dy" or beta == "d-y" or beta == "dai-yuan" then
      self.beta = "DY"
   else
      error("flos.CG could not determine beta method.")
   end

   -- Check restart method
   local restart = self.restart:lower()
   if restart == "negative" then
      self.restart = "negative"
   elseif restart == "powell" or restart == "p" then
      self.restart = "Powell"
   else
      error("flos.CG could not determine restart method.")
   end

end


--- Reset the CG algorithm for restart purposes
-- All history will be cleared and the algorithm will restart the CG
-- optimization from scratch.
function CG:reset()
   optim.Optimizer.reset(self)
   self.G0, self.G = nil, nil
   self.conj0, self.conj = nil, nil
   self.line:reset()
end


--- Add the current parameters and the gradient for those to the history
-- @Array F the parameters
-- @Array G the gradient for the function with the parameters `F`
function CG:add_history(F, G)

   -- Cycle data
   self.G0 = self.G
   self.conj0 = self.conj

   -- Store current data (the current conjugate direction
   -- will be updated in .optimize)
   self.G = G:copy()

end


--- Returns the optimized parameters which should minimize the function
-- with respect to the current conjugate gradient
-- @Array F the parameters for the function
-- @Array G the gradient for the parameters
-- @return a new set of parameters to be used for the function
function CG:optimize(F, G)

   local new = nil

   -- Be sure to update the optimized parameter (for the CG method)
   self:optimized(G)

   if self.G == nil then
      -- This is the first CG step

      -- cycle history
      self:add_history(F, G)

      -- Initialize the current conjugate direction with G
      self.conj = G:copy()

      -- Ensure line-search is reset
      self.line:reset()

      -- Perform line-optimization
      new = self.line:optimize(F, self.conj)

      self.niter = self.niter + 1

   elseif self.line:optimized(G) then
      -- The line-optimizer has finished and we should step the
      -- steepest descent direction.

      --print("CG new conjugate direction")
      -- We cycle the history and calculate the next steepest
      -- descent direction
      self:add_history(F, G)

      -- Calculate the next conjugate direction
      self.conj = self:conjugate()

      -- Reset line-search
      self.line:reset()

      -- Perform line-optimization
      new = self.line:optimize(F, self.conj)

      self.niter = self.niter + 1

   else

      --print("CG continue line-optimization")

      -- Continue with the line-search algorithm
      new = self.line:optimize(F, G)
			       
   end

   -- Check whether we have finalized the optimization
   -- to the given tolerance
   return new

end

--- Return the new conjugate direction
-- This will take into account how the beta-value is calculated.
-- @return the new conjugate direction
function CG:conjugate()

   -- The beta value to determine the step of the steepest descent direction
   local beta
   
   if self.beta == "PR" then
      
      beta = self.G:flatten():dot( (self.G - self.G0):flatten() ) /
	 self.G0:flatten():dot( self.G0:flatten() )
      
   elseif self.beta == "FR" then
      
      beta = self.G:flatten():dot(self.G:flatten()) /
	 self.G0:flatten():dot( self.G0:flatten() )
      
   elseif self.beta == "HS" then
      
      local d = (self.G - self.G0):flatten()
      beta = - self.G:flatten():dot(d) /
	 self.conj0:flatten():dot(d)
      
   elseif self.beta == "DY" then
      
      beta = - self.G:flatten():dot(self.G:flatten()) /
	 self.conj0:flatten():dot( (self.G - self.G0):flatten() )
      
   end

   if self.restart == "negative" then

      beta = m.max(0., beta)

   elseif self.restart == "Powell" then

      -- Here we check whether the gradient of the current iteration
      -- has "lost" orthogonality to the previous iteration
      local n = self.G:norm(0) ^ 2
      if self.G:flatten():dot( self.G0:flatten() ) / n >= 0.2 then

	 -- There is a loss of orthogonality and we restart the CG algorithm
	 beta = 0.

      end

   end

   -- Damp memory for beta (older steepest descent directions
   -- loose value over minimizations), smooth restart.
   beta = beta * self.beta_damping

   --print("CG: beta = " .. tostring(beta))

   -- Now calculate the new steepest descent direction
   return self.G + beta * self.conj0

end


--- SIESTA function for performing a complete SIESTA CG optimization.
--
-- This function will query these fdf-flags from SIESTA:
--
--  - MD.MaxForceTol
--  - MD.MaxCGDispl
--
-- and use those as the tolerance for convergence as well as the
-- maximum displacement for each optimization step.
--
-- Everything else is controlled by the `CG` object.
--
-- Note that all internal operations in this function relies on units being in
--  - Ang
--  - eV
--  - eV/Ang
--
-- @tparam table siesta the SIESTA global table.
function CG:SIESTA(siesta)

   -- Retrieve the siesta units
   local unit = siesta.Units

   if siesta.state == siesta.INITIALIZE then

      -- Setup the convergence criteria
      siesta.receive({"MD.MaxDispl",
		      "MD.MaxForceTol"})
      
      self.tolerance = siesta.MD.MaxForceTol * unit.Ang / unit.eV
      self.max_dF = siesta.MD.MaxDispl / unit.Ang
      -- Propagate the tolerances down to the line-search for reducing
      -- amount of line-searches
      self.line.tolerance = self.tolerance
      self.line.max_dF = self.max_dF -- this is not used
      self.line.optimizer.tolerance = self.tolerance -- this is not used
      self.line.optimizer.max_dF = self.max_dF -- this is used

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


--- Print some information regarding the `CG` object
function CG:info()
   
   print("")
   if self.beta == "PR" then
      print("CG: beta method: Polak-Ribiere")
   elseif self.beta == "FR" then
      print("CG: beta method: Fletcher-Reeves")
   elseif self.beta == "HS" then
      print("CG: beta method: Hestenes-Stiefel")
   elseif self.beta == "DY" then
      print("CG: beta method: Dai-Yuan")
   end
   print("CG: beta-damping "..tostring(self.beta_damping))
   print("CG: Restart "..tostring(self.restart))

   print("CG: Tolerance "..tostring(self.tolerance))
   print("CG: Iterations "..tostring(self.niter))

   print("CG: line search:")
   self.line:info()
   print("")

end

return CG
