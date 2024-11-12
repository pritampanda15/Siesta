---
-- Implementation of the Fast-Inertial-Relaxation-Engine
-- @classmod FIRE
-- The implementation has several options related to the
-- original method.
--
-- 
local m = require "math"
local mc = require "flos.middleclass.middleclass"

local num = require "flos.num"
local optim = require "flos.optima.base"

-- Create the FIRE class (inheriting the Optimizer construct)
local FIRE = mc.class("FIRE", optim.Optimizer)

--- Instantiating a new `FIRE` object.
--
-- The parameters _must_ be specified with a table of fields and values.
--
-- The `FIRE` optimizer implements several variations of the original FIRE
-- algorithm.
--
-- Here we allow to differentiate on how to normalize the displacements:
--
-- -  `correct` (argument for `FIRE:new`)
--    - "global" perform a global normalization of the coordinates (maintain displacement direction)
--    - "local" perform a local normalization (for each direction of each atom) (displacement direction is not maintained)
-- -  `direction` (argument for `FIRE:new`)
--    - "global" perform a global normalization of the velocities (maintain gradient direction)
--    - "local" perform a local normalization of the velocity (for each atom) (gradient direction is not maintained)
--
-- This `FIRE` optimizer allows two variations of the scaling of the velocities
-- and the resulting displacement.
--
--
-- @usage
-- fire = FIRE{<field1 = value>, <field2 = value>}
-- while not fire:optimized() do
--    F = fire:optimize(F, G)
-- end
--
-- @function FIRE:new
-- @number[opt=0.5] dt_init initial time-step
-- @number[opt=10*dt_init] dt_max maximum time-step allowed
-- @number[opt=1.1] f_inc factor used to increase time-step
-- @number[opt=0.5] f_dec factor used to decrease time-step
-- @number[opt=0.99] f_alpha factor used to decrease alpha-parameter
-- @number[opt=0.1] alpha_init initial alpha-parameter
-- @int[opt=5] N_min minimum number of iterations performed before time-step may be increased
-- @string[opt="global"] correct how the new parameters are rescaled, `"global"` or `"local"`
-- @string[opt="global"] direction how the velocity pparameter is scaled, `"global"` or `"local"`
-- @tparam[opt=1] ?number|table mass control individually the masses of each atom
-- @param ... any arguments `Optimizer:new` accepts
local function doc_function()
end


function FIRE:initialize(tbl)
   -- Initialize from generic optimizer
   optim.Optimizer.initialize(self)

   local tbl = tbl or {}

   -- All variables are defined as given in the FIRE
   -- paper.

   -- Initial time-step
   self.dt_init = 0.5

   -- Increment and decrement values
   self.f_inc = 1.1
   self.f_dec = 0.5
   
   -- The decrement value for the alpha parameter
   self.f_alpha = 0.99

   -- Initial alpha parameter
   self.alpha_init = 0.1

   -- Number of consecutive iterations required with
   -- P = F. v > 0 before we increase the time-step
   self.N_min = 5
   -- Counter for number of P > 0
   -- When n_P_pos >= N_min we step the time-step
   self.n_P_pos = 0
   
   -- Special options regarding the FIRE algorithm

   -- This value can be either "local" or "global"
   -- For "global" the correction of the displacements
   -- are using a rescaling of the global coordinates.
   -- For "local" each coordinate is rescaled.
   self.correct = "global"

   -- This value can be either "local" or "global"
   -- For "global" velocity operator are rescaled
   -- according to the global norm.
   -- For "local" each atoms velocity is maintained.
   self.direction = "global"

   -- Ensure we update the elements as passed
   -- by new(...)
   if type(tbl) == "table" then
      for k, v in pairs(tbl) do
	 if k == "mass" then
	    self:set_mass(v)
	 else
	    self[k] = v
	 end
      end
   end

   -- Maximum time-step
   if tbl.dt_max == nil then
      self.dt_max = 10 * self.dt_init
   end

   -- Initialize the variables
   self:reset()

   if self.direction ~= "global" and self.direction ~= "local" then
      error("FIRE: direction variable *MUST* be either local/global!")
   end
   if self.correct ~= "global" and self.correct ~= "local" then
      error("FIRE: correct variable *MUST* be either local/global!")
   end

end


--- Reset FIRE algorithm by resetting initial parameters (`dt` and `alpha`)
-- All masses are also set to 1.
function FIRE:reset()
   optim.Optimizer.reset(self)
   self.dt = self.dt_init
   self.alpha = self.alpha_init
   if self.mass == nil then
      self:set_mass()
   end
end


--- Set the velocity for the FIRE algorithm
-- @Array V an `Array` which has the atomic velocities
function FIRE:set_velocity(V)
   -- Set the internal current velocity
   self.V = V:copy()
end

--- Set the masses for all atoms.
-- @Array mass may either be a single number (all atoms have same mass), or an `Array`
--   which may contain different masses per atom.
function FIRE:set_mass(mass)
   if mass == nil then
      -- Create fake mass with all same masses
      -- No need to duplicate data, we simply
      -- create a metatable (deferred lookup table with
      -- the same return value).
      self.mass = setmetatable({},
			       { __index = 
				    function(t,k)
				       return 1.
				    end,
			       })
   else
      self.mass = mass:copy()
   end
end


--- Normalize the parameter displacement to a given max-change.
-- The FIRE algorithm has an option which determines whether
-- a global normalization occurs (maintain gradient), or
-- whether a local normalization takes place.
-- @Array dF the parameter displacements that are to be normalized
-- @return the normalized `dF` according to the `global` or `local` correction
function FIRE:correct_dF(dF)

   if self.correct == "global" then
      
      -- Calculate the maximum norm
      local max_norm = dF:norm():max()
      
      -- Now normalize the displacement
      local norm = self.max_dF / max_norm
      if norm < 1. then
	 return dF * norm
      else
	 return dF
      end

   elseif self.correct == "local" then

      -- Copy so we can operate on the displacements
      local d = dF:copy()
      for i = 1, #d do
	 for j = 1, #d[i] do
	    if m.abs(d[i][j]) > self.max_dF then
	       -- Ensure we have the correct sign
	       if d[i][j] >= 0. then
		  d[i][j] = self.max_dF
	       else
		  d[i][j] = -self.max_dF
	       end
	    end
	 end
      end
      return d
   else
      error("FIRE: correct variable *must* be local/global!")
   end
   
end


--- Perform a FIRE step with input parameters `F` and gradient `G`
-- @Array F the parameters for the function
-- @Array G the gradient for the function with parameters `F`
-- @return a new set of parameters which should converge towards a
--   local minimum point.
function FIRE:optimize(F, G)

   if self.V == nil then
      -- Force the content of a velocity
      self:set_velocity(F * 0.)
   end

   -- Determine whether we have optimized the parameter/functional
   -- We need to do this before we begin the iteration because
   -- of the possible constraint enforced subsequently
   self:optimized(G)

   -- First we figure out if there are non-constrained atoms
   local min_norm = G:norm():min()
   if min_norm ~= 0. then
      -- Figure out the atom with the smallest force
      local norm = 0.
      local j = 1
      for i = 1, #G do
	 norm = G[i]:norm()
	 if norm == min_norm then
	    j = i
	    break
	 end
      end
      -- currently we force the first atom to be fixed
      j = 1
      print(("FIRE: %e"):format(min_norm))
      print(("FIRE:  ENFORCING CONSTRAINT ON ATOM: %d"):format(j))
      print("FIRE: The FIRE algorithm is MD based and requires at least a fixed atom!")
      print("FIRE:")
      G[j]:fill(0.)
   end

   -- Calculate power
   local P = G:flatdot(self.V)

   local V
   if P > 0. then

      -- Update velocity
      V = (1. - self.alpha) * self.V

      
      --[[
	 Here there are two choices:
	 1. Either the update of the velocity is, per coordinate, or
	 2. The updated velocity is globally adjusted.
      --]]

      if self.direction == "global" then
	 
	 -- This is the globally adjusted version:
	 V = V + self.alpha * G / G:norm(0) * self.V:norm(0)

      elseif self.direction == "local" then
	 
	 -- Per coordinate version:
	 for i = 1, #V do
	    local n = G[i]:norm()
	    if n ~= 0. then
	       V[i] = V[i] + self.alpha * G[i] / n * self.V[i]:norm()
	    end
	 end
	 
      else
	 error("FIRE: direction variable *must* be global/local!")
      end

      if self.n_P_pos >= self.N_min then
	 
	 -- We have had _many_ positive P and we may increase time-step
	 self.dt = m.min(self.dt * self.f_inc, self.dt_max)
	 self.alpha = self.alpha * self.f_alpha

      end

      -- Increment counter for positive power
      self.n_P_pos = self.n_P_pos + 1

   else
      -- We have a negative power, and thus we are climbing up, reset velocity
      V = self.V * 0.

      -- Decrease time-step and reset alpha
      self.dt = self.dt * self.f_dec
      self.alpha = self.alpha_init

      -- Reset counter for negative power
      self.n_P_pos = 0

   end

   -- Now perform a typical MD step
   local dF = self:MD(V, G)

   -- Update the weight of the algorithm
   self.weight = m.abs(G:flatdot(dF))
   
   -- Correct to the max displacement
   dF = self:correct_dF(dF)

   -- Update the internal velocity
   self:set_velocity(V + G * self.dt)
   
   -- Update iteration counter
   self.niter = self.niter + 1

   -- return next step regardless of optimization
   return F + dF
end


--- Internal function for performing an MD step
-- This routine performs an Euler step with mid-point correction
-- which takes into account the end-point gradient position as well.
--
-- If one desires to use another MD-stepping algorithm one may
-- overload this function.
-- @Array V the velocities
-- @Array G the gradient
-- @return the step size of the parameters
function FIRE:MD(V, G)
   -- V == velocity
   -- G == gradient/force

   -- This MD is an euler with mid-point correction as implemented in SIESTA
   -- The equation is:
   --   dF = V(0) * dT / 2 + V(dT) * dT / 2
   --      = V(0) * dT / 2 + [V(0) + G*dT] * dT / 2
   --      = [V(0) + G*dT / 2] * dT
   return (V + G * (self.dt / 2)) * self.dt

   -- If we use what VTST uses it is a direct Euler
   --return V * self.dt + G * (self.dt * self.dt)
end


--- SIESTA function for performing a complete SIESTA FIRE optimization.
--
-- This function will query these fdf-flags from SIESTA:
--
--  - MD.MaxForceTol
--  - MD.MaxCGDispl
--
-- and use those as the tolerance for convergence as well as the
-- maximum displacement for each optimization step.
--
-- Everything else is controlled by the `FIRE` object.
--
-- Note that all internal operations in this function relies on units being in
--  - Ang
--  - eV
--  - eV/Ang
--
-- @tparam table siesta the SIESTA global table.
function FIRE:SIESTA(siesta)

   -- Retrieve the siesta units
   local unit = siesta.Units

   if siesta.state == siesta.INITIALIZE then

      -- Setup the convergence criteria
      siesta.receive({"MD.MaxDispl",
		      "MD.MaxForceTol"})
      
      self.tolerance = siesta.MD.MaxForceTol * unit.Ang / unit.eV
      self.max_dF = siesta.MD.MaxDispl / unit.Ang

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


--- Print information regarding the FIRE algorithm
function FIRE:info()

   print("")
   print(("FIRE: dT initial / current / max:  %.4f / %.4f / %.4f fs"):format(self.dt_init, self.dt, self.dt_max))
   print(("FIRE: alpha initial / current:  %.4f /  %.4f"):format(self.alpha_init, self.alpha))
   print(("FIRE: # of positive G.V %d"):format(self.n_P_pos))
   print(("FIRE: Tolerance %.4f"):format(self.tolerance))
   print(("FIRE: Maximum change %.4f "):format(self.max_dF))
   print("FIRE: Direction update: "..self.direction)
   print("FIRE: Correction update: "..self.correct)
   print("")

end

return FIRE
