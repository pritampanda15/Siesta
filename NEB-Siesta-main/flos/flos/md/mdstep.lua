---
-- A class for retaining MD-steps with optionally associated variables
-- @classmod MDStep
--
-- The MDStep class retains information on a single MD step.
-- Such a step may be represented by numerous quantities.
-- One may always add new information, but it may for instance
-- be used to retain information such as:
--  `R`, the atomic coordinates
--  `V`, the velocities
--  `F`, the forces
--  `E`, an energy associated with the current step.
--

local mc = require "flos.middleclass.middleclass"

local MDStep = mc.class("MDStep")

function MDStep:initialize(args)

   -- Initialize an MDStep class with the appropriate table quantities

   -- Ensure we update the elements as passed
   -- by new(...)
   if type(args) == "table" then
      for k, v in pairs(args) do
	 self[k] = v
      end
   end
   
end

--- Set a specific value in the MDStep class
-- This routine easily enables specifying a set of
-- values simultaneously:
--
--     MDStep:set{ R=R, F=F, E=E}
--
-- and one may subsequently query the data through:
--
--     R, F, E = MDStep.R, MDStep.F, MDStep.E
function MDStep:set(args)

   -- Routine for setting specific settings through
   -- direct table additions, i.e.
   --   MDStep:set(R= R)
   -- will subsequently allow:
   --   MDStep.R
   -- queries.

   for k, v in pairs(args) do
      self[k] = v
   end
end


--- Shorthand for `MDStep:set{R=R}`
function MDStep:set_R(R)
   self:set{R=R}
end
--- Shorthand for `MDStep:set{V=V}`
function MDStep:set_V(V)
   self:set{V=V}
end
--- Shorthand for `MDStep:set{F=F}`
function MDStep:set_F(F)
   self:set{F=F}
end
--- Shorthand for `MDStep:set{E=E}`
function MDStep:set_E(E)
   self:set{E=E}
end

-- Easy printing routine for show the content
function MDStep:print()
   for k, v in pairs(self) do
      print(k, v)
   end
end

return MDStep
