--[[
Wrapper for loading a lot of the flos
tool suite.

Here we add all the necessary tools that
the flos library allows.
--]]

local ret = {}

local function add_ret( tbl )
   for k, v in pairs(tbl) do
      ret[k] = v
   end
end

add_ret(require "flos.error")
add_ret(require "flos.num")
-- MD-stuff
add_ret(require "flos.md")
-- LBFGS algorithm and other optimizers
add_ret(require "flos.optima")
-- ForceHessian MD method and other methods
add_ret(require "flos.special")
-- Fast creation of simple tables
add_ret(require "flos.table")

return ret
