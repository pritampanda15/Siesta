--[[ 
Create a table with the default parameters of 
the special functions that are going to be inherited.
--]]

-- Create returning table
local ret = {}

ret.ForceHessian = require "flos.special.forcehessian"
ret.NEB = require "flos.special.neb"
ret.DNEB = require "flos.special.dneb"

return ret
