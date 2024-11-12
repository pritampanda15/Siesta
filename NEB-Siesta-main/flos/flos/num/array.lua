---
-- Implementation of ND Arrays in Lua.
-- @classmod Array
-- A generic implementation of ND arrays in pure Lua.
-- This module tries to be as similar to the Python numpy package
-- as possible.
--
-- Due to everything being in Lua there are not _views_ of arrays which
-- means that many functions creates unnecessary data-duplications.
-- This may be leveraged in later code implementations.
--
-- The underlying Array class is implemented as follows:
--
--  1. Every Array gets associated a `Shape` which determines the size
--  of the current Array.
--  2. If the Array is > 1D all elements `Array[i]` is an array
--  with sub-Arrays of one less dimension.
--  3. This enables one to call any Array function on sub-partitions
--  of the Array without having to think about the details.
--  4. The special case is the last dimension which contains the actual
--  data.
--
-- The `Array` class is using the same names as the Python numerical library
-- `numpy` for clarity.

local m = require "math"
local mc = require "flos.middleclass.middleclass"

local ferr = require "flos.error"
local error = ferr.floserr
local shape = require "flos.num.shape"

local Array = mc.class("Array")

--- Check if a variable is an `Array` type object.
-- @param obj the object/variable to check
-- @int[opt=0] dim query the exact dimensionality of the `Array` (`0` for _any_ dimensionality)
-- @return true if the object is an instance, or sub-class, of `Array`, and possibly also whether
--   the dimensionality is as queried.
local function isArray(obj, dim)
   local d = dim or 0
   if type(obj) == "table" then
      if obj.class then
	 local bool = obj:isInstanceOf(Array) or obj:isSubclassOf(Array)
	 if bool and d > 0 then
	    bool = #obj.shape == d
	 end
	 return bool
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


function Array:initialize(...)

   local sh = nil

   -- One may also initialize an Array by passing a
   -- shape class, so we need to check this
   local args = {...}
   if shape.isShape(args[1]) then
      sh = args[1]:copy()
   end
	    
   if sh == nil then
      sh = shape.Shape(...)
   end

   -- Create the shape container
   rawset(self, "shape", sh)

   -- For each size along the first dimension
   -- we create a new one for each of them
   if #self.shape > 1 then
      for i = 1, #self do
	 rawset(self, i, Array( table.unpack(self.shape, 2) ))
      end
   end

end

-- Internal function which inserts numerical values if they are not existing.
-- Checks whether the index is within the shape of the `Array`.
-- @param i the index of the value
-- @param v the value of the index
function Array:__newindex(i, v)
   -- A new index *must* by definition be the last array
   -- in the shape
   if #self.shape ~= 1 then
      error("flos.Array error in implementation")
   end
   if i < 1 or #self < i then
      error("flos.Array setting element out of bounds")
   end
   rawset(self, i, v)
end

--- Initialization routines.
--
-- Several routines exists to initialize the `Array` with values.
--
-- @usage
--   Array:empty(2, 3) -- it is the users responsibility to assign values
--   Array(2, 3) -- same as :empty
--   Array:ones(2, 3) -- filled with 1's all over
--   Array:zeros(2, 3) -- filled with 0's all over
--   Array:range(2, 3) -- array with values [2, 3]
--   Array:ones(2, 3):copy() -- create a copy of another Array
-- @section init

--- Initialization routine for the Array object.
-- Create a new empty `Array`. Remark that no entries are defined.
-- 
-- @usage
--   Array(2, 3) -- an array with the last element being `[2][3]`
--   Array(2, 3, 4) -- an array with the last element being `[2][3][4]`
--   Array( Shape(3, 2) ) -- an array with the last element being `[3][2]`
--
-- @function Array:new
-- @param ... a comma-separated list of integers, or a `Shape`
-- @return a new Array object with the given shape
local function doc_function()
end

--- Initialize an Array, equivalent to `Array(...)`.
-- @param ... the shape of the Array
-- @return an Array with no values set, it is the users responsibility to assign values before
--   proceeding with other calculations
function Array.empty(...)
   return Array(...)
end

--- Initialize an Array filled with 0's, equivalent to `a = Array(...); a:fill(0.)`
-- @param ... the shape of the Array
-- @return an Array with all values set to 0.
function Array.zeros(...)
   -- Initialize the object
   local arr = Array(...)
   -- Fill all values with 0.
   arr:fill(0.)
   -- Return the array
   return arr
end

--- Initialize an Array filled with 1's, equivalent to `a = Array(...); a:fill(1.)`
-- @param ... the shape of the Array
-- @return an Array with all values set to 1.
function Array.ones(...)
   -- Initialize the object
   local arr = Array(...)
   -- Fill all values with 1.
   arr:fill(1.)
   -- Return the array
   return arr
end


--- Create a deep copy of the array by copying all elements.
-- @return a copy of the Array
function Array:copy()
   local new = Array( self.shape:copy() )
   if #self.shape == 1 then
      -- We need to extract the values, rather than
      -- copying
      for i = 1, #self do
	 new[i] = self[i]
      end
   else
      for i = 1, #self do
	 new[i] = self[i]:copy()
      end
   end
   return new
end

--- Initialize a 1D Array with a linear spacing of values starting from `i1`, ending with `i2` and with step size `step` which defaults to 1.
-- @note this function is not similar to the `numpy.arange` function because it
--   includes the last value.
-- @param i1 the initial value of the range
-- @param i2 the last value of the range (if `(i2-i1+1)/step` is a float the last element is not necessarily in the array)
-- @param[opt=1] step the stepsize between consecutive values.
-- @return an Array with equally separated values.
function Array.range(i1, i2, step)
   -- Get the actual step (default 1)
   local is = step or 1
   if is == 0 then
      error("flos.Array range with zero step-length creates an infinite table.")
   elseif is > 0 and i1 > i2 then
      error("flos.Array range with positive step-length and i1 > i2 is not allowed.")
   elseif is < 0 and i1 < i2 then
      error("flos.Array range with negative step-length and i1 < i2 is not allowed.")
   end

   local new = Array.empty( 1 )
   local j = 0
   for i = i1, i2, is do
      j = j + 1
      if i ~= i1 then
	 new.shape[1] = new.shape[1] + 1
      end
      new[j] = i
   end

   return new
end


--- Object information.
--
--
-- Routines to retrieve information regarding the `Array` object
-- I.e. the shape, total size, etc.
-- @usage
--   #Array -- length of first dimension
--   #Array.shape -- number of dimensions
--   Array.size([dim]) -- size of dimension, total size if `dim=0`
-- @section info

--- Query the length of the first dimension of the Array
-- @return the length of the first dimension, `self.shape[1]`
function Array:__len()
   return self.shape[1]
end

--- Query the size of the Array, @see Shape:size.
-- @int[opt=0] axis optional argument to query specific axes, if not supplied
--   the total size of the array will be returned.
-- @return the length of the specified axis (or total size).
function Array:size(axis)
   return self.shape:size(axis)
end


--- Get an `Array` element through a linear index of the ND array
-- @int i linear index in the (possible) ND array
function Array:get_linear(i)

   -- If we are at the last dimension, return immediately.
   if #self.shape == 1 then
      return self[i]
   end

   -- Calculate # of elements per first dimension
   local n_dim = self:size() / self:size(1)
   -- Calculate the first dimension index
   local j = m.tointeger( m.ceil(i / n_dim) )
   -- Transform i into the linear index in the underlying array
   return self[j]:get_linear( m.tointeger(i - (j-1) * n_dim) )
end


--- Set an `Array` element through a linear index of the ND array
-- @int i linear index in the (possible) ND array
-- @param v the value to be set at index `i`
function Array:set_linear(i, v)

   -- If we are at the last dimension, return immediately.
   if #self.shape == 1 then

      self[i] = v

      return
   end

   -- Calculate # of elements per first dimension
   local n_dim = self:size() / self:size(1)
   -- Calculate the first dimension index
   local j = m.tointeger( m.ceil(i / n_dim) )
   -- Transform i into the linear index in the underlying array
   self[j]:set_linear( m.tointeger(i - (j-1) * n_dim), v)

end


--- Manipulation routines.
--
-- All these routines can change the content and do operations of
-- `Array` objects.
--
-- @section computation


--- Fill all values in the Array with a given value.
-- @param val the value of all elements of this Array
function Array:fill(val)
   if #self.shape == 1 then
      -- We are at the last dimension so we set
      -- the value accordingly
      for i = 1, #self do
	 self[i] = val
      end
   else
      for i = 1, #self do
	 self[i]:fill(val)
      end
   end
end


--- Return a deep copy of the Array with a different shape
--
-- @usage
--   a = Array:zeros(4, 4)
--   b = a:reshape(0) -- Array:zeros(16)
--   c = a:reshape(2, 0) -- Array:zeros(2, 8)
--   d = a:reshape(0, 2) -- Array:zeros(8, 2)
-- @param ... the new shape of the array, any of the provided dimension
--   sizes may be a 0 (or `nil`) which indicates that the length of said
--   dimension will be inferred from the total size of the Array
-- @return an Array with the same total size and values, but with different shape
function Array:reshape(...)
   local arg = {...}
   if #arg == 0 then
      arg[1] = 0
   end

   -- In case a shape is passed
   local sh
   if shape.isShape(arg[1]) then
      sh = self.shape:align( arg[1] )
   else
      sh = self.shape:align( shape.Shape(table.unpack(arg)) )
   end
   if sh == nil then
      error("flos.Array cannot align shapes, incompatible dimensions")
   end

   -- Create the new array
   local new = Array( sh )

   -- Loop on the linear indices
   for i = 1, self:size() do
      new:set_linear(i, self:get_linear(i))
   end

   return new
end

--- Return a deep copy of the Array in a 1D array (equivalent to `:reshape(0)`)
-- @return a 1D-Array with the same total size and values, but with a single dimension
function Array:flatten()
   return self:reshape( 0 )
end


--- Return the Array as a copy with every element mapped through the given function
-- The function should accept a single value, and return a single value (not a table).
-- @param func the cast function
-- @return an Array with every element mapped through the function `func`
function Array:map(func)
   local ar = Array( self.shape:copy() )

   -- Now create all values
   if #ar.shape == 1 then

      -- Process all elements
      for i = 1, #ar do
	 ar[i] = func(self[i])
      end

   else

      -- Process all dimensions
      for i = 1, #ar do
	 ar[i] = self[i]:map(func)
      end

   end

   return ar
end

--- Elementwise absolute operation
-- @return `math.abs(Array)`
-- @see math.abs
function Array:abs()
   return self:map(m.abs)
end

--- Elementwise ceiling operation
-- @return `math.ceil(Array)`
-- @see math.ceil
function Array:ceil()
   return self:map(m.ceil)
end

--- Elementwise floor operation
-- @return `math.floor(Array)`
-- @see math.floor
function Array:floor()
   return self:map(m.floor)
end

--- Elementwise conversion to integer
-- @return all values as integers (`math.tointeger(Array)`)
-- @see math.tointeger
function Array:tointeger()
   return self:map(m.tointeger)
end

--- Elementwise exponential operation
-- @return `math.exp(Array)`
-- @see math.exp
function Array:exp()
   return self:map(m.exp)
end

--- Elementwise cosine operation
-- @return `math.cos(Array)`
-- @see math.cos
function Array:cos()
   return self:map(m.cos)
end

--- Elementwise sine operation
-- @return `math.sin(Array)`
-- @see math.sin
function Array:sin()
   return self:map(m.sin)
end

--- Elementwise logarithm operation
-- @param[opt=e] base the base of the logarithm
-- @return `math.log(Array, base)`
-- @see math.log
function Array:log(base)
   if base == nil then
      return self:map(m.log)
   end

   -- Create local function with different base
   local function lb(v)
      return m.log(v, base)
   end
   return self:map(lb)
end

--- Elementwise tangent operation
-- @return `math.tan(Array)`
-- @see math.tan
function Array:tan()
   return self:map(m.tan)
end

--- Elementwise square root operation
-- @return `math.sqrt(Array)`
-- @see math.sqrt
function Array:sqrt()
   return self:map(m.sqrt)
end

--- Elementwise cube-root operation
-- @return `Array ^ (1./3)`
function Array:cbrt()
   return self ^ ( 1. / 3 )
end


--- Return the product of array elements over a given axis
-- @int[opt=0] axis optional argument to query specific axes, if not supplied
--   the total product of the array will be returned.
-- @return the product of the specified axis (or total product)
function Array:prod(axis)
   local ax = ax_(axis)

   -- Return prod
   local prod

   if ax == 0 then

      -- we do a full product
      prod = 1.
      for i = 1, #self do
	 prod = prod * self[i]:prod()
      end

   else

      error("flos.Array prod, not implemented for anything but full")

   end

   return prod
end

--- Return a the norm of the Array.
-- @usage
--    a = Array( 2, 3)
--    a:fill(1.)
--    print(a:norm(2)) -- [3 ^ 0.5, 3 ^ 0.5]
--    print(a:norm(0)) -- 6 ^ 0.5
-- @int[opt=#self.shape] axis the axis along which the norm is taken, defaults to the last dimension, currently any axis between 0 and the last dimension is not implemented.
-- @return a value if the `axis=0` or the Array is 1D, else a new Array with 1 less dimension is returned.
function Array:norm(axis)
   local ax
   if #self.shape == 1 then
      -- Force the linear one
      -- This is required because of ax == 0 cases for the last dimension.
      ax = 1
   else
      ax = ax_(axis or #self.shape)
   end

   -- Return norm
   local norm

   if ax == 0 then

      -- we do a 1D norm
      norm = 0.
      for i = 1, #self do
	 norm = norm + self[i]:norm(0) ^ 2
      end
      norm = m.sqrt(norm)

   elseif #self.shape == 1 then

      norm = 0.
      for i = 1, #self do
	 norm = norm + self[i] * self[i]
      end
      norm = m.sqrt(norm)

   else

      -- We remove the last dimension and take the norm for
      -- each direction
      norm = Array( self.shape:remove(#self.shape) )
      for i = 1, #norm do
	 norm[i] = self[i]:norm()
      end

   end

   return norm
end


--- Return the scalar projection of this array onto another.
-- Example:
--    a = Array( 2, 3)
--    print(a:scalar_project( Array.ones( 2, 3) )
--
-- The scalar projection is this formula:
--    $\frac{a \cdot b}{|b|}$
-- @Array P the projection array (if 0, the returned projection will be 0)
-- @int[opt=0] axis the axis along the projection, currently only a full projection is available
-- @return a value if the `axis=0` or the Array is 1D, else a new Array with 1 less dimension is returned.
function Array:scalar_project(P, axis)
   local ax = ax_(axis)

   if ax == 0 then

      local norm = P:norm(0)

      if norm == 0. then
	 -- This means that P is the 0 vector so we can't project to it
	 -- We return 0
	 return 0.
      end

      -- Calculate norm of the projection vector
      return self:flatten():dot( P:flatten() ) / norm

   else

      error("flos.Array could not project on anything but flattened array")

   end

end


--- Return the projection of this array onto another.
-- Example:
--    a = Array( 2, 3)
--    print(a:project( Array.ones( 2, 3) )
--
-- The scalar projection is this formula:
--    $\frac{a \cdot b}{|b|^2} b$
-- @Array P the projection array (if 0, the returned projection will be 0)
-- @int[opt=0] axis the axis along the projection, currently only a full projection is available
-- @return a value if the `axis=0` or the Array is 1D, else a new Array with 1 less dimension is returned.
function Array:project(P, axis)
   local ax = ax_(axis)

   if ax == 0 then

      -- Calculate norm of the projection vector
      local dnorm2 = P:norm(0) ^ 2
      if dnorm2 == 0. then
	 -- This means that P is the 0 vector so we can't project to it
	 -- We return 0
	 return Array.zeros( self.shape:flatten() )
      end

      return self:flatten():dot( P:flatten() ) / dnorm2 * P

   else

      error("flos.Array could not project on anything but flattened array")

   end

end


--- Return the minimum value of the Array
-- @int[opt=0] axis either 0 or an axis. If 0 (or `nil`) the global minimum is returned, else along the given dimension
-- @return a value if the `axis=0` or an Array with one less dimension (the axis dimension is _removed_).
function Array:min(axis)
   local ax = ax_(axis)

   -- Returned minimum
   local min

   -- Now figure out what to do
   if ax == 0 then

      -- We simply need to extract the total minimum
      if #self.shape == 1 then
	 min = self[1]
	 for i = 2, #self do
	    min = m.min(min, self[i])
	 end
      else
	 min = self[1]:min(0)
	 for i = 2, #self do
	    min = m.min(min, self[i]:min(0))
	 end
      end

   else
      min = Array( self.shape:remove(ax) )

      error("NotimplementedYet")
   end

   return min
end


--- Return the maximum value of the Array
-- @int[opt=0] axis either 0 or an axis. If 0 (or `nil`) the global maximum is returned, else along the given dimension
-- @return a value if the `axis=0` or an Array with one less dimension (the axis dimension is _removed_).
function Array:max(axis)
   local ax = ax_(axis)

   -- Returned maximum
   local max

   -- Now figure out what to do
   if ax == 0 then

      -- We simply need to extract the total minimum
      if #self.shape == 1 then
	 max = self[1]
	 for i = 2, #self do
	    max = m.max(max, self[i])
	 end
      else
	 max = self[1]:max(0)
	 for i = 2, #self do
	    max = m.max(max, self[i]:max(0))
	 end
      end

   else
      max = Array( self.shape:remove(ax) )

      error("NotimplementedYet")
   end

   return max
end

--- Return the sum of elements of the Array
-- @int[opt=0] axis either 0 or an axis. If 0 (or `nil`) the global sum is returned, else along the given dimension
-- @return a value if the `axis=0` or an Array with one less dimension (the axis dimension is _removed_).
function Array:sum(axis)
   -- Get the actual axis
   local ax = ax_(axis)

   local sum
   if ax == 0 then

      -- Special case for the 1D case
      if #self.shape == 1 then
	 sum = self[1]
	 for i = 2, #self do
	    sum = sum + self[i]
	 end

      else

	 sum = self[1]:sum(0)
	 for i = 2, #self do
	    sum = sum + self[i]:sum(0)
	 end

      end

   elseif ax > #self.shape then
      error("flos.Array sum must be along an existing dimension")
   else

      -- Create the new array
      sum = Array( self.shape:remove(ax) )
      error("flos.Array sum not implemented yet")

   end

   return sum
end


--- Return the average of elements of the Array
-- @int[opt=0] axis either 0 or an axis. If 0 (or `nil`) the global average is returned, else along the given dimension
-- @return a value if the `axis=0` or an Array with one less dimension (the axis dimension is _removed_).
function Array:average(axis)
   -- Get the actual axis
   local ax = ax_(axis)

   local avg
   if ax == 0 then

      avg = self:sum(0) / self:size()

   elseif ax > #self.shape then
      error("flos.Array average must be along an existing dimension")
   else

      -- Create the new array
      avg = Array( self.shape:remove(ax) )
      error("flos.Array average not implemented yet")

   end

   return avg
end


--- Return the sum of cross-product of two arrays (only for 1D arrays with `#Array == 3`)
-- @Array lhs the left-hand side of the operand
-- @Array rhs the second operand of the cross-product
-- @return an Array with the cross-product of the two vectors
function Array.cross(lhs, rhs)

   local sh = lhs.shape:align(rhs.shape)
   if sh == nil then
      error("flos.Array cross product does not have aligned shapes")
   end
   if lhs.shape[#lhs.shape] ~= 3 or rhs.shape[#rhs.shape] ~= 3 then
      error("flos.Array cross product requires the last dimension to have length 3")
   end

   local cross = Array( sh )

   if #cross.shape == 1 then

      cross[1] = lhs[2] * rhs[3] - lhs[3] * rhs[2]
      cross[2] = lhs[3] * rhs[1] - lhs[1] * rhs[3]
      cross[3] = lhs[1] * rhs[2] - lhs[2] * rhs[1]

   elseif lhs.shape == rhs.shape then
      -- We must do it on each of the arrays, in this case
      -- we can easily loop
      for i = 1, sh[1] do
	 cross[i] = lhs[i]:cross(rhs[i])
      end

   else

      error("flos.Array cross not implemented for non-equivalent shapes")
   end

   return cross
end


--- Wrapper for doing a linear dot-product between any two ND arrays, the only
-- requirement is that they have the same total size.
-- @Array lhs the first operand of the dot-product
-- @Array rhs the second operand of the dot-product
-- @return the value of the dot-product
function Array.flatdot(lhs, rhs)

   local size = lhs:size()
   if size ~= rhs:size() then
      error("flos.Array flatdot requires same length of the arrays")
   end

   local dot = lhs:get_linear(1) * rhs:get_linear(1)
   for i = 2, size do
      dot = dot + lhs:get_linear(i) * rhs:get_linear(i)
   end
   return dot
end


--- Dot-product of two Arrays.
-- For 1D arrays this returns a single value,
-- for ND arrays the shapes must fulfil `self.shape[#self.shape] == other.shape[1]`,
-- as well as all dimensions `self.shape[1:#self.shape-2] == other.shape[3:].reverse()`.
-- Note that for 2D Arrays this is equivalent to matrix-multiplication.
-- @Array lhs the first operand of the dot-product.
-- @Array rhs the second operand of the dot-product.
-- @return a single value if both Arrays are 1D, else a new Array is returned.
function Array.dot(lhs, rhs)

   -- The returned dot-product
   local dot

   -- Check if they are 1D Arrays
   if #lhs.shape == 1 and #rhs.shape == 1 then

      -- sum(lhs * rhs)
      if lhs.shape ~= rhs.shape then
	 error("flos.Array dot dimensions for 1D dot product are not the same")
      end

      -- This is a element wise product and sum
      dot = 0.
      for i = 1, #lhs do
	 dot = dot + lhs[i] * rhs[i]
      end

   elseif #lhs.shape == 1 and #rhs.shape == 2 then

      -- lhs ^ T . rhs => vec

      if #lhs ~= #rhs then
	 error("flos.Array dot dimensions for 1D-2D dot product are not the same")
      end

      -- This is a element wise product and sum
      dot = Array( rhs.shape[2] )
      for j = 1, #dot do
	 local v = lhs[1] * rhs[1][j]
	 for i = 2, #lhs do
	    v = v + lhs[i] * rhs[i][j]
	 end
	 dot[j] = v
      end

   elseif #lhs.shape == 2 and #rhs.shape == 1 then

      -- lhs . rhs => vec

      if lhs.shape[2] ~= rhs.shape[1] then
	 error("flos.Array dot dimensions for 2D-1D dot product are not the same")
      end

      -- This is a element wise product and sum
      dot = Array( #lhs )
      for i = 1, #dot do
	 dot[i] = lhs[i]:dot(rhs)
      end

   elseif #lhs.shape == 2 and #rhs.shape == 2 then

      -- Check that the shapes coincide
      if lhs.shape[2] ~= rhs.shape[1] then
	 error("flos.Array dot product 2D-2D must have inner dimensions equivalent lhs.shape[2] == rhs.shape[1]")
      end

      -- The easy case, align the shapes
      local sh = shape.Shape( lhs.shape[1], rhs.shape[2] )
      dot = Array( sh )

      -- loop inner
      for j = 1 , #lhs do
	 dot[j] = lhs[j]:dot(rhs)
      end

   else

      error("flos.Array dot for arrays with anything but 1 or 2 dimensions is not implemented yet")

   end

   return dot

end


--- Return the transpose of the Array (all dimensions are swapped).
-- @return a copy of the Array with all dimensions reversed.
function Array:transpose()

   -- Check dimensions, we cannot transpose a 1D array
   local nd = #self.shape
   local new = nil

   if nd == 1 then
      return self:copy()

   elseif nd == 2 then

      -- Create return array
      new = Array( self.shape:reverse() )

      for i = 1 , self.shape[1] do
	 for j = 1 , self.shape[2] do
	    new[j][i] = self[i][j]
	 end
      end

   elseif nd == 3 then

      -- Create return array
      new = Array( self.shape:reverse() )

      for i = 1 , self.shape[1] do
	 for j = 1 , self.shape[2] do
	    for k = 1 , self.shape[3] do
	       new[k][j][i] = self[i][j][k]
	    end
	 end
      end

   else

      error("flos.Array transpose only works up to 3D arrays")

   end

   return new
end


--- Elementwise addition of two arrays.
-- It is required that both operands have the same shape (or
-- one of them being a scalar).
-- @param lhs the first operand (`Array` or `number`)
-- @param rhs the second operand (`Array` or `number`)
-- @return an Array with `lhs + rhs`
function Array.__add(lhs, rhs)

   -- Create the return value
   local ret

   -- Determine whether they are both the Arrays
   if isArray(lhs) and isArray(rhs) then

      -- Check if the shapes align (for element wise addition)
      local sh = lhs.shape:align(rhs.shape)
      if sh == nil then
	 error("flos.Array + requires the same shape for two different Arrays")
      end

      -- Create the return array
      ret = Array( lhs.shape )
      -- Element-wise additions
      for i = 1, #lhs do
	 ret[i] = lhs[i] + rhs[i]
      end

   elseif isArray(lhs) then

      ret = Array( lhs.shape )

      -- Add scalar to all LHS
      for i = 1, #lhs do
	 ret[i] = lhs[i] + rhs
      end

   elseif isArray(rhs) then

      -- Add scalar to all RHS
      ret = Array( rhs.shape )

      for i = 1, #rhs do
	 ret[i] = lhs + rhs[i]
      end

   else
      error("flos.Array + could not figure out the types")
   end

   return ret

end

--- Elementwise subtraction of two arrays (see `Array:__add`)
-- @param lhs the first operand
-- @param rhs the second operand
-- @return an Array with `lhs - rhs`
function Array.__sub(lhs, rhs)
   local ret
   if isArray(lhs) and isArray(rhs) then
      local sh = lhs.shape:align(rhs.shape)
      if sh == nil then
	 error("flos.Array - requires the same shape for two different Arrays")
      end
      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] - rhs[i]
      end
   elseif isArray(lhs) then
      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] - rhs
      end
   elseif isArray(rhs) then
      ret = Array( rhs.shape )
      for i = 1, #rhs do
	 ret[i] = lhs - rhs[i]
      end
   else
      error("flos.Array - could not figure out the types")
   end
   return ret
end

--- Elementwise multiplication of two arrays (see `Array:__add`)
-- @param lhs the first operand
-- @param rhs the second operand
-- @return an Array with `lhs * rhs`
function Array.__mul(lhs, rhs)
   local ret
   if isArray(lhs) and isArray(rhs) then
      local sh = lhs.shape:align(rhs.shape)
      if sh == nil then
	 error("flos.Array * requires the same shape for two different Arrays")
      end
      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] * rhs[i]
      end
   elseif isArray(lhs) then
      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] * rhs
      end
   elseif isArray(rhs) then
      ret = Array( rhs.shape )
      for i = 1, #rhs do
	 ret[i] = lhs * rhs[i]
      end
   else
      error("flos.Array * could not figure out the types")
   end
   return ret
end

--- Elementwise modulo (%) of two arrays (see `Array:__add`)
-- @param lhs the first operand
-- @param rhs the second operand
-- @return an Array with `lhs % rhs`
function Array.__mod(lhs, rhs)
   local ret
   if isArray(lhs) and isArray(rhs) then
      local sh = lhs.shape:align(rhs.shape)
      if sh == nil then
	 error("flos.Array % requires the same shape for two different Arrays")
      end
      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] % rhs[i]
      end
   elseif isArray(lhs) then
      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] % rhs
      end
   elseif isArray(rhs) then
      ret = Array( rhs.shape )
      for i = 1, #rhs do
	 ret[i] = lhs % rhs[i]
      end
   else
      error("flos.Array % could not figure out the types")
   end
   return ret
end

--- Elementwise division of two arrays (see `Array:__add`)
-- @param lhs the first operand
-- @param rhs the second operand
-- @return an Array with `lhs / rhs`
function Array.__div(lhs, rhs)
   local ret
   if isArray(lhs) and isArray(rhs) then
      local sh = lhs.shape:align(rhs.shape)
      if sh == nil then
	 error("flos.Array / requires the same shape for two different Arrays")
      end
      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] / rhs[i]
      end
   elseif isArray(lhs) then
      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] / rhs
      end
   elseif isArray(rhs) then
      ret = Array( rhs.shape )
      for i = 1, #rhs do
	 ret[i] = lhs / rhs[i]
      end
   else
      error("flos.Array / could not figure out the types")
   end
   return ret
end

--- Elementwise unary negation
-- @return an Array with `-self`
function Array:__unm()
   local ret = Array( self.shape:copy() )
   for i = 1, #self do
      ret[i] = -self[i]
   end
   return ret
end

--- Elementwise power of two arrays (see `Array:__add`)
-- @param lhs the first operand
-- @param rhs the second operand, this may be "T" to indicate a transpose, @see Array:transpose
-- @return an Array with `lhs ^ rhs`, or the transpose if `rhs == "T"`.
function Array.__pow(lhs, rhs)
   local ret
   if isArray(lhs) and isArray(rhs) then
      local sh = lhs.shape:align(rhs.shape)
      if sh == nil then
	 error("flos.Array ^ requires the same shape for two different Arrays")
      end

      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] ^ rhs[i]
      end
   elseif isArray(lhs) then
      -- Check for transposition
      if type(rhs) == "string" and rhs == "T" then
	 return lhs:transpose()
      end

      ret = Array( lhs.shape )
      for i = 1, #lhs do
	 ret[i] = lhs[i] ^ rhs
      end
   elseif isArray(rhs) then
      -- Check for transposition
      if type(lhs) == "string" and lhs == "T" then
	 return rhs:transpose()
      end

      ret = Array( rhs.shape )
      for i = 1, #rhs do
	 ret[i] = lhs ^ rhs[i]
      end
   else
      error("flos.Array ^ could not figure out the types")
   end
   return ret
end

--- Return the values of the array in a tabular format as a string.
-- Currently the values are presented in a %12.5e format.
-- @return a string representation of the Array
function Array:__tostring()
   local ns = #self.shape
   local s = "["
   if ns == 1 then
      for i = 1, #self do
	 s = s .. ("%12.5e"):format(self[i])
	 if i < #self then
	    s = s .. ", "
	 end
      end
   else
      for i = 1, #self do
	 s = s .. tostring(self[i])
	 if i < #self then
	    s = s .. ",\n "
	 end
      end
   end
   return s .. "]"
end

--- Write the values to an already open file-handle
-- The format is defined via the `format` parameter and the content gets
-- an empty line at the end of the array pri
-- @param handle the file-handle to write to
-- @param[opt="%20.13e"] format the output format of the values
-- @param[opt="\n"] footer a string to write after the array values has been written
function Array:savetxt(handle, format, footer)
   local fmt = format or "%20.13e"
   local foot = footer or "\n"

   local ns = #self.shape

   if ns == 1 then

      local s = fmt:format(self[1])
      for i = 2, #self do
	 s = s .. " " .. fmt:format(self[i])
      end
      s = s .. "\n" .. foot
      handle:write(s)

   elseif ns == 2 then

      for i = 1, #self do
	 -- The 2D data will be stored as a "matrix"
	 self[i]:savetxt(handle, fmt, "")
      end
      handle:write(foot)

   else

      for i = 1, #self do
	 -- Each dimension will be separated by a newline
	 self[i]:savetxt(handle, fmt, "\n")
      end
      handle:write(foot)

   end

end

-- Simple recursive function to return a comma separated list
-- of dimension sizes.
local function table_size_(tbl)
   if type(tbl) == "table" then
      return #tbl, table_size_(tbl[1])
   else
      return
   end
end


--- Given a regular Lua table this function returns a new Array
-- with elements filled from the table.
-- @tparam table tbl the input table.
-- @return an Array with elements corresponding to the values in `tbl`
function Array.from(tbl)

   local sh = shape.Shape( table_size_(tbl) )
   -- Create array and prepare to loop
   local arr = Array( sh )
   if #arr.shape == 1 then
      for i = 1, #arr do
	 arr[i] = tbl[i]
      end
   else
      for i = 1, #arr do
	 arr[i] = Array.from(tbl[i])
      end
   end
   return arr
end

-- Return table
return {
   ["Array"] = Array,
   ["isArray"] = isArray,
}
