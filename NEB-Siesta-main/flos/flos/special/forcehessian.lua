--[[ 
This module implements the force-constants routine
for doing an FC run with optimized displacements
according to the maximum displacement.
--]]

local m = require "math"
local mc = require "flos.middleclass.middleclass"

local ferr = require "flos.error"
local error = ferr.floserr

-- Class for performing force-constant runs
local ForceHessian = mc.class('ForceHessian')

function ForceHessian:initialize(xa, indices, displacement, mass)

   -- Performing an FC run requires
   -- a few things
   --
   -- 1. the initial atomic coordinates (from where the initial force constants are runned)
   -- 2. the indices of the atoms that should be displaced
   -- 3. the maximum displacement of the lightest atom (defaults to 0.02 Ang)
   -- 4. the mass of the atoms (to scale the displacements)
   --    If not supplied they will all be the same

   -- We copy them because we need to be sure that they
   -- work
   self.xa = xa:copy()

   -- Ensure that everything is an integer
   self.indices = indices:map(m.tointeger)

   self:set_displacement(displacement)
   -- Optional argument
   self:set_mass(mass)

   -- Calculate the maximum mass
   self.mass_max = 0.
   for i = 1, #self.mass do
      self.mass_max = m.max(self.mass_max, self.mass[i])
   end

   -- Local variables for tracking the FC run
   self.iter = 0
   self.dir = 1

   -- Create variable for 0 forces
   self.F0 = nil
   
   -- Create table for the forces of the other atoms
   self.F = {}
   for i = 1, #self.indices do
      local ia = self.indices[i]
      self.F[ia] = {}
   end
   
   -- Create fake Force table to always be
   -- able to return 0
   -- This is 3 levels because of:
   --  DIR, na, 3
   fake3 = setmetatable({},
			{ __len =
			     function(tbl)
				return 3
			     end,
			  __index =
			     function(t, k)
				return 0.
			     end,
			})
   fakeF = setmetatable({},
			{ __len =
			     function(tbl)
				return #self.xa
			     end,
			  __index =
			     function(t, k)
				return fake3
			     end,
			})
   fake = setmetatable({},
		       { __len =
			    function(tbl)
			       return 6
			    end,
			 __index =
			    function(t, k)
			       return fakeF
			    end,
		       })

   for ia = 1, #self.xa do
      if self.F[ia] == nil then
	 -- add a fake table (just in case
	 -- somebody tries to access it)
	 self.F[ia] = fake
      end
   end
   
end

-- Whether or not the FC displacement is complete
function ForceHessian:done()
   return self.iter > #self.indices
end

-- Calculate the displacement of atom ia
-- Note that the displacement will be largest
-- on the heaviest atom, and smallest on the
-- lightest atom.
function ForceHessian:displacement( ia )
   return m.sqrt(self.mass[ia] / self.mass_max) * self.displ
end

-- Retrieve the next coordinates for the FC run
function ForceHessian:next(fa)

   -- Get copy of the xa0 coordinates
   local xa = self.xa:copy()
   local ia
   local dx
   
   -- The first step
   if self.iter == 0 then
      self.iter = 1
      self.dir = 0

      -- Store the initial forces
      if fa ~= nil then
	 self.F0 = fa:copy()
      end

   elseif fa ~= nil then
      
      -- Store the forces from the previous displacement
      ia = self.indices[ self.iter ]
      dx = self:displacement(ia)
      -- After this is the output equivalent to the
      -- SIESTA output
      if self.dir % 2 == 0 then
	 dx = - dx
      end
      -- Normalize to get: eV / Ang ^ 2
      self.F[ia][self.dir] = (fa - self.F0) / dx
      
   end
   
   -- In case the last move was the last displacement of
   -- the previous atom
   if self.dir == 6 then
      self.dir = 0
      self.iter = self.iter + 1
   end

   -- In case we have just stepped outside of the
   -- displacement atoms
   if self:done() then
      return xa
   end

   -- Update the direction
   self.dir = self.dir + 1

   -- Calculate the displacement of atom ia
   ia = self.indices[ self.iter ]
   dx = self:displacement( ia )
   
   if     self.dir == 1 then
      xa[ia][1] = xa[ia][1] - dx
   elseif self.dir == 2 then
      xa[ia][1] = xa[ia][1] + dx
   elseif self.dir == 3 then
      xa[ia][2] = xa[ia][2] - dx
   elseif self.dir == 4 then
      xa[ia][2] = xa[ia][2] + dx
   elseif self.dir == 5 then
      xa[ia][3] = xa[ia][3] - dx
   elseif self.dir == 6 then
      xa[ia][3] = xa[ia][3] + dx
   end

   return xa
   
end


-- Return the force from the ia'th atom, in the direction
-- and in positive/negative
function ForceHessian:force(ia, direction, pos_neg)
   local i
   if direction == "x" then
      i = 1
   elseif direction == "y" then
      i = 3
   elseif direction == "z" then
      i = 5
   else
      error("ForceHessian:force could not decipher the direction")
   end
   if pos_neg == "+" then
      i = i + 1
   elseif pos_neg == "-" then
      -- nothing
   else
      error("ForceHessian:force could not decipher the positive-negative")
   end

   return self.F[ia][i]
end

-- Return the symmetrized force constant
-- normalized with the displacement of the atom
function ForceHessian:symmetrize_force(ia, direction)
   return (self:force(ia, direction, "+") +
	      self:force(ia, direction, "-") ) / 2
end


-- Reset counters to restart the calculation
-- One may optionally set the new displacement
function ForceHessian:reset(displacement)

   self.iter = 0
   self.dir = 1

   if displacement ~= nil then
      self:set_displacement(displacement)
   end

end

-- Update the displacement, if not nil
function ForceHessian:set_displacement(displacement)
   self.displ = displacement
end

-- Update the masses, if nil, all masses will be the same
function ForceHessian:set_mass(mass)
   if mass == nil then
      -- Create fake mass with all same masses
      -- No need to duplicate data, we simply
      -- create a metatable (deferred lookup table with
      -- the same return value).
      self.mass = setmetatable({},
			       { __len =
				    function (tbl)
				       return #self.xa
				    end,
				 __index = 
				    function(t,k)
				       return 1.
				    end,
			       })
   else
      self.mass = mass
   end
end

-- Store all the Force constants in a file
function ForceHessian:save(filename, symmetrized)
   -- Open the file (ready for writing)
   local file = io.open(filename, "w")

   local lsym
   if symmetrized ~= nil then
      lsym = symmetrized
   else
      lsym = false
   end

   if lsym then
      file:write("Force constants matrix, [F(+,0,0)+F(-,0,0)]/2; [F(0,+,0)+F(0,-,0)]/2; [F(0,0,+)+F(0,0,-)]/2\n")
   else
      file:write("Force constants matrix, F(+,0,0); F(-,0,0); F(0,+,0); F(0,-,0); F(0,0,+); F(0,0,-)\n")
   end
   file:write( ("MaxDisplacement: %f Ang\n"):format(self.displ) )
   file:write( ("Atoms: %d\n"):format(#self.xa) )

   -- Create force write-out local function
   local output = function(fa)
      local fmt = " %20.13e %20.13e %20.13e\n"
      for i = 1, #fa do
	 file:write( fmt:format(fa[i][1], fa[i][2], fa[i][3]) )
      end
   end

   for i = 1, #self.indices do
      local ia = self.indices[i]

      if self.iter <= i then
	 -- stop writing (the iteration count must be more
	 break
      end

      -- Write out which atom we have displaced
      local displ = self:displacement(ia)
      file:write( ("\nDisplacedAtom: %d / %f Ang\n"):format(ia, displ) )

      for _, dir in pairs({"x", "y", "z"}) do
	 if lsym then
	    output(self:symmetrize_force(ia, dir))
	 else
	    output(self:force(ia, dir, "-"))
	    output(self:force(ia, dir, "+"))
	 end
      end

   end

   file:close()

end

return ForceHessian
