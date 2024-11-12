--[[
Wrapper for loading the numerical linear algebra library for flos
--]]

local ret = {}

local function add_ret( tbl )
   for k, v in pairs(tbl) do
      ret[k] = v
   end
end

add_ret(require "flos.num.linalg.linalg")

return ret

