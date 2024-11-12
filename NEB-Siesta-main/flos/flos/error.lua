--- Module to handle intrinsic flos errors.
-- @module error
--
-- Generic routines for returning error messages are present
-- in this module.

--- Preferred flos error call (instead of `error`).
-- Discription; This function will always print a stack-trace by
-- removing itself from the stack.
-- @param ... the full field to be passed to the `error` function
local floserr = function(...)
   
   -- Print out a stack-trace without this function call
   print(debug.traceback(nil, 2))
   error(...)
   
end

return {
   ['floserr'] = floserr,
}
