--[[
Wrapper for loading the numerical library for flos
--]]

local ret = {}

local function add_ret( tbl )
   for k, v in pairs(tbl) do
      ret[k] = v
   end
end

add_ret(require "flos.num.shape")
add_ret(require "flos.num.array")

return ret

