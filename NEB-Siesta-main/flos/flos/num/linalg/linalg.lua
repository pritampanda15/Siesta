---
-- Implementation of linear algebra for the `Array` type defined in `flos.num`.
-- @module Linear algebra
--
-- Module for implementation functions for performing linear algebra routines.
--
-- The operations performed on matrices are function based and requires explicit
-- arguments.

local m = require "math"

-- Load the Array table
local num = require "flos.num"
local ferr = require "flos.error"
local error = ferr.floserr

-- Create return table
local ret = {}


--- Calculate the inverse of a square matrix (`Array` of 2 dimensions with equal size)
-- @return same size `Array` with the inverse matrix, if the matrix has a zero in the diagonal
--  a single negative integer is returned which corresponds to the diagonal element that is non-zero.
local function inverse(A)
   -- Check 2D array
   if not num.isArray(A, 2) then
      error("flos.num.linalg inverse incorrect dimensionality of inverse matrix (dim ~= 2)")
   end
   -- Check sizes of dimensions
   if A.shape[1] ~= A.shape[2] then
      error("flos.num.linalg inverse requires a square matrix")
   end

   -- size of matrix
   local N = A.shape[1]

   -- Check whether we have non-zeroes in full diagonal (simple check)
   for i = 1, N do
      if A[i][i] == 0. then
	 -- signal non-invertible matrix
	 return -i
      end
   end

   -- Create inverse matrix
   local inv = A:copy()

   for i = 1, N do
      
      local x = 1._dp / inv[i][i]
      
      inv[i][i] = 1.
      for j = 1, N do
	 inv[i] = inv[i] * x
      end

      for k = 1, N do
	 if k - i ~= 0 then
	    x = inv[k][i]
	    inv[k][i] = 0.

	    inv[k] = inv[k] - (inv[i] * x):sum()

	 end
      end
   end

   return inv
end
-- Populate return table
ret.inverse = inverse

return ret
