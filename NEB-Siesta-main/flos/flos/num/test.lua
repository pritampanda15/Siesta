
local array = require "flos.num"

v1 = array.Array( 6 )
print(#v1, v1:size())
for i = 1, #v1 do
   v1[i] = i
end

v2 = array.Array.empty(6, 6)
k = 0
for i = 1, #v2 do
   for j = 1, #v2[i] do
      v2[i][j] = i * j + k
   end
   k = k + 1
end
print(#v2, v2:size())

print('Array1D dot Array1D')
print(v1:dot(v1))

print('Array2D dot Array1D')
print(v2:dot(v1))

print('Array1D dot Array2D')
print(v1:dot(v2))

print('Array2D ^ T')
print(v2 ^ "T")

local function sprint(v1, v2)
   print(v1.shape, v2.shape)
end

print('Array1D: reshaping, explicit')
sprint(v1, v1:reshape(0))

print('Array1D: reshaping, implicit')
sprint(v1, v1:reshape())

print('Array1D: reshaping, other')
sprint(v1, v1:reshape(2, 0))

print('Array1D: reshaping, other')
sprint(v1, v1:reshape(0, 2))

print('Array2D: reshaping, explicit')
sprint(v2, v2:reshape(0))

print('Array2D: reshaping, implicit')
sprint(v2, v2:reshape())

print('Array2D: reshaping, other')
sprint(v2, v2:reshape(12, 0))

print('Array2D: reshaping, other')
sprint(v2, v2:reshape(0, 12))

print('Array1D: range')
print(array.Array.range(1, -34, -3))

print('Array1D: copy')
print(array.Array.ones(3, 4):copy())
