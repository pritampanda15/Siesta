---
-- A module for easy creating several tables with different properties.
-- @module Tables
--

--- A factory for creating a table with default variables and/or default functions
-- @tparam table variables default values assigned to the table (currently does not work for
--                     creating copies of tables)
-- @tparam table empty_functions a table of names that are to be created as functions (doing nothing, returning nothing)
-- @tparam table functions a named table with functions that are copied to the table
-- @return a table with the above parameters expanded as content in the table
--
-- @usage
-- variables = {Hello = 1, Test = nil}
-- empty_functions = {"first", "second"}
-- functions = {third = function(...) print('Hello') end}
-- tbl = table_factory{variablse=variable, empty_functions=empty_function, functions=functions}
-- tbl.Hello == 1
-- tbl.first()
-- tbl.third() -- prints Hello
local table_factory = function(tbl)
   local V = tbl["variables"] or {}
   local EF = tbl["empty_functions"] or {}
   local F = tbl["functions"] or {}

   -- Create table to be returned
   local tbl = {}

   -- Copy variables
   for name, v in pairs(V) do
      tbl[name] = v
   end

   -- Create empty functions
   for i, f in ipairs(EF) do
      tbl[f] = function(...) end
   end

   -- Copy functions
   for name, f in pairs(F) do
      tbl[name] = f
   end

   return tbl
end

return {table_factory=table_factory}
