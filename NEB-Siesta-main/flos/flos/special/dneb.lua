---
-- D-NEB class
-- @classmod DNEB

local mc = require "flos.middleclass.middleclass"
local _NEB = require "flos.special.neb"

-- Create the D-NEB class
local DNEB = mc.class("DNEB", _NEB)


--- Calculate perpendicular spring force for a given image
-- @int image image to calculate the perpendicular spring force of
-- @return the perpendicular spring force
function DNEB:perpendicular_spring_force(image)
   -- We don't need to check image (these function calls does exactly that)
   local S_F = self:spring_force(image)

   -- Return the new perpendicular spring force
   return S_F - S_F:project( self:tangent(image) )
end


-- Now we need to overwrite the calculation of the NEB-force

--- Calculate the resulting NEB force of a given image
-- @int image the image to calculate the NEB force of
-- @return NEB force
function DNEB:neb_force(image)
   -- Calculate *original* NEB force
   local NEB_F = _NEB.neb_force(self, image)

   -- Only correct in case we are past climbing
   if self.niter > self._climbing and self:climbing(image) then
      return NEB_F
   end

   local PS_F = self:perpendicular_spring_force(image)
   local P_F = self:perpendicular_force(image)
   
   -- This is equivalent to:
   --   flatdot(PS_F, P_F) / norm(P_F)^2 * P_F .* P_F
   -- with .* being the elementwise multiplication
   return NEB_F + PS_F - PS_F:project( P_F ) * P_F
end

return DNEB
