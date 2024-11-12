---
-- Implementation of Shape to control the size of arrays (@see Array)
-- @classmod Shape
-- A helper class for managing the size of `Array`s. 
--
-- Having the Shape of an array in a separate class makes it much easier
-- to implement a flexible interface for interacting with Arrays.
--
-- A Shape is basically a table which defines the size of the Array,
-- the dimensions of the Array is `#Shape` while each axis size may
-- be queried by `Shape[axis]`.
-- Additionally a Shape may have a single dimension with size `0` which
-- may _only_ be used to align two shapes, i.e. the `0` axis is inferred
-- from the total size of the aligning Shape.

local m = require "math"
local mc = require "flos.middleclass.middleclass"

local ferr = require "flos.error"
local error = ferr.floserr

-- Create the shape class (globally so it returns)
local Shape = mc.class("Shape")

--- Check if a variable is a a Shape type object.
-- @param obj the object/variable to check
-- @return true if the object is an instance, or sub-class, of the Shape
local function isShape(obj)
   if type(obj) == "table" then
      if obj.class then
	 return obj:isInstanceOf(Shape) or obj:isSubclassOf(Shape)
      end
   end
   return false
end

-- Function for returning the axis as provided by transfering nil to 0
local function ax_(axis)
   if axis == nil then
      return 0
   else
      return axis
   end
end


--- Initialization routine for the Shape object.
-- Examples:
--     Shape(2, 3) -- a shape with 2 dimensions of given sizes
--     Shape(2, 3, 4) -- a shape with 3 dimensions
-- @param ... a comma-separated list of integers
-- @return a new Shape object with the given shape
function Shape:initialize(...)
   local args = {...}

   if #args == 0 then
      error("flos.Shape must have at least one dimension")
   end

   local zero = false
   for i, v in ipairs(args) do
      rawset(self, i, v)
      if v == 0 then
	 if zero then
	    error("flos.Shape must not be initialized with more than one 0 value.")
	 end
	 zero = true
      end
   end

end

--- Copy the shape by duplicating the dimension sizes
-- @return a new Shape with the same content
function Shape:copy()
   return Shape( table.unpack(self) )
end

--- Create a new shape with all dimensions flattened
-- @return a Shape with 1 dimension equal to the total size
function Shape:flatten()
   return Shape( self:size() )
end


--- Reverse the dimension sizes, `Shape( 2, 3, 4):reverse() == Shape( 4, 3, 2)`
-- @return a new Shape
function Shape:reverse()
   -- create the reversed shape
   local sh = {}
   for i = #self, 1, -1 do
      sh[#sh+1] = m.tointeger(self[i])
   end
   -- This is the new shape
   return Shape( table.unpack(sh) )
end

--- Query the size of the Shape, either a given dimension, or the total size
-- @int[opt=0] axis the dimension one wish to query (0 for total)
-- @return the size of the dimension (as an integer)
function Shape:size(axis)
   local ax = ax_(axis)
   local size = 1
   if ax == 0 then
      -- We return the full size
      for _, v in ipairs(self) do
	 if v ~= 0 then
	    size = size * v
	 end
      end
   else
      size = self[ax]
   end
   return m.tointeger(size)
end

--- Removes a dimension from the Shape
-- @return a new shape with the given axis removed
function Shape:remove(axis)
   local ax = ax_(axis)
   if ax == 0 then
      error("flos.Shape removing an axis requires a specific axis")
   end
   local s = {}
   for i, v in ipairs(self) do
      if i ~= ax then
	 s[#s+1] = v
      end
   end
   if #s == 0 then
      return nil
   end
   return Shape( table.unpack(s) )
end


--- Query index of the first zero index
-- @return the first axis with a zero size, if none, `0` is returned
function Shape:zero()
   for i, v in ipairs(self) do
      if v == 0 then
	 return i
      end
   end
   return 0
end


--- Return a new shape such that the shapes are equal in size
-- In case either shape has a 0-size dimension that size will be
-- calculated so that the total size is the same.
-- @param other the shape to compare with
-- @return a new Shape which is a copy of `other` if they already are aligned
function Shape:align(other)
   if other == nil then
      return self:copy()
   end

   local zero_s = self:zero()
   local zero_o = other:zero()
   local size_s = self:size()
   local size_o = other:size()

   -- Now check that they are the same
   if zero_s ~= 0 and zero_o ~= 0 then
      return nil
      
   elseif zero_s ~= 0 then
      -- we align ->, not to the left
      return nil
      
   elseif zero_o ~= 0 then

      local n = size_s / size_o
      if n * size_o ~= size_s then
	 return nil
      end

      local new = other:copy()
      new[zero_o] = m.tointeger(n)
      return new

   elseif self:size() ~= other:size() then

      -- The shapes are not the same...
      return nil

   else

      -- The shape is copied because they are the same
      return other:copy()

   end
end

--- Convert the Shape to a pretty-printed string
-- @return a string with the dimensions of the shape in a comma separated string
function Shape:__tostring()
   local s = "[" .. tostring(self[1])
   for i = 2 , #self do
      s = s .. ', ' .. tostring(self[i])
   end
   return s .. ']'
end
   

--- Checks whether two Shapes are the same (with respect to dimensions)
-- @return `true` if each dimension is the same
function Shape.__eq(a, b)
   if #a ~= #b then
      return false
   end
   
   for i, v in ipairs(a) do
      if v ~= b[i] then
	 return false
      end
   end
   
   return true
end


-- The return table for this module
return {
   ["Shape"] = Shape,
   ["isShape"] = isShape,
}
