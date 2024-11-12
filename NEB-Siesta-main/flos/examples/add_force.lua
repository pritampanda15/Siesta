--[[
Example on how to add a constant force to a Siesta run using flos.

Here there is only one parameter.

  force_file

which is formatted as the siesta.FA file.

--]]

-- Set this to the file that contains the additive forces.
local force_file = nil


-- Everything below this point need (should) not be touched.

-- Load the FLOS module
local flos = require "flos"

-- Grab the unit table of siesta (it is already created
-- by SIESTA)
local Unit = siesta.Units

local add_force = {}


-- Function for reading a geometry
local read_fa = function(filename)
   local file = io.open(filename, "r")
   local na = tonumber(file:read())
   local F = flos.Array.zeros(na, 3)
   local i = 0
   local function tovector(s)
      local t = {}
      s:gsub('%S+', function(n) t[#t+1] = tonumber(n) end)
      return t
   end
   for i = 1, na do
      local line = file:read()
      if line == nil then break end
      -- Get stuff into the R
      local v = tovector(line)
      F[i][1] = v[2]
      F[i][2] = v[3]
      F[i][3] = v[4]
   end
   file:close()
   return flos.Array.from(F)
end


function siesta_comm()
   
   -- Do the actual communication with SIESTA
   if siesta.state == siesta.INITIALIZE then

      -- Readed forces *must* be in eV/Ang, will convert to Ry/Bohr
      add_force = read_fa(force_file) / Unit.Ang * Unit.eV

      -- Print information
      IOprint("\nLUA Added forces")

   end

   if siesta.state == siesta.FORCES then
      
      -- We retrieve the current coordinates, the forces
      -- and whether the geometry has relaxed
      siesta.receive({"geom.fa"})

      siesta.geom.fa = flos.Array.from(siesta.geom.fa) + add_force

      siesta.send({"geom.fa"})

   end
end
