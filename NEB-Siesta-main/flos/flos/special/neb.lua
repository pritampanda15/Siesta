---
-- NEB class
-- @classmod NEB

local m = require "math"
local mc = require "flos.middleclass.middleclass"

local array = require "flos.num"
local ferror = require "flos.error"
local error = ferror.floserr

-- Create the NEB class (inheriting the Optimizer construct)
local NEB = mc.class("NEB")

--- Instantiating a new `NEB` object.
--
-- For the `NEB` object it is important to pass the images, and _then_ all
-- the NEB settings as named arguments in a table.
--
-- The `NEB` object implements a generic NEB algorithm as detailed in:
--
--  1. "Improved tangent estimate in the nudged elastic band method for finding minimum energy paths and saddle points", Henkelman & Jonsson, JCP (113), 2000
--  2. "A climbing image nudged elastic band method for finding saddle points and minimum energy paths", Henkelman, Uberuaga, & Jonsson, JCP (113), 2000
--
-- This particular implementation has been tested and initially developed by Jesper T. Rasmussen, DTU Nanotech, 2016.
--
-- When instantiating a new `NEB` calculator one _must_ populate the initial, all intermediate images and a final image in a a table.
-- The easiest way to do this can be seen in the below usage field.
--
-- To perform the NEB calculation all images (besides the initial and final) are
-- relaxed by an external relaxation method (see `Optimizer` and its child classes).
-- Due to the forces being highly non-linear as the NEB algorithm updates the
-- forces depending on the nearest images, it is adviced to use an MD-like relaxation
-- method such as `FIRE`. If one uses history based relaxation methods (`LBFGS`, `CG`, etc.) one should
-- limit the number of history steps used.
--
-- Running the NEB class will create a huge list of files with corresponding output.
-- Check the `NEB:save` function for details.
--
-- @usage
-- -- Read in the images
-- -- Note that `read_geom` must be a function that you define to read in the
-- -- atomic coordinates of a corresponding `.xyz` file.
-- -- Either let the NEB class interpolate, or do it manually.
-- images = {initial=read_geom("initial.xyz"), final=read_geom("final.xyz")}
-- images["n_images"] = 6 -- 6 images (between initial and final)
-- -- or, do it manually:
-- --[
-- images = {}
-- for i = 2, n_images do
--    images[#images+1] = flos.MDStep{R=read_geom(image_label .. i .. ".xyz")}
-- end
-- --]
-- neb = NEB(images, {<field1 = value>, <field2 = value>})
-- relax = {}
-- for i = 1, neb.n_images do
--    relax[i] = flos.FIRE()
-- end
-- neb[0]:set(F=<initial-forces>, E=<initial-E>)
-- neb[neb.n_images+1]:set(F=<final-forces>, E=<final-E>)
-- while true do
--    -- Calculate all forces and energies of each image
--    for i = 1, neb.n_images do
--       neb[i]:set(F=<forces>, E=<energy>)
--    end
--    -- Calculate new positions (this must be done after
--    -- the force calculations because the coordinates depend on the
--    -- neighbouring image forces)
--    R = {}
--    for i = 1, neb.n_images do
--       f = neb:force(i)
--       R[i] = relax:optimize(neb[i].R, neb:force(i))
--    end
--    for i = 1, neb.n_images do
--       neb:set(R=R[i])
--    end
-- end
--
-- @function NEB:new
-- @tparam table images all images (including initial and final) or with 3 keys, "initial", "final" and "n_images" for linear interpolation.
-- @tparam[opt=5.] ?number|table k spring constant between the images, a table can be used for individual spring constants
-- @number[opt=5] climbing after this number of iterations the climbing image will be taken into account (to disable climbing, pass `false`)
-- @number[opt=0.005] climbing_tol the tolerance for determining whether an image is climbing or not
local function doc_function()
end


-- Initialization routine
function NEB:initialize(images, tbl)
   -- Convert the remaining arguments to a table
   local tbl = tbl or {}

   local img = {}

   if #images == 0 or images["initial"] ~= nil then
      -- We handle 3 different cases:
      local md = require "flos.md"
      local initial
      local final

      if md.MDStep.isInstanceOf(images["initial"], md.MDStep) then
	 initial = images["initial"].R
	 final = images["final"].R
      elseif array.Array.isInstanceOf(images["initial"], array.Array) then
	 initial = images["initial"]
	 final = images["final"]
      else
	 initial = array.Array(images["initial"])
	 final = array.Array(images["final"])
      end
      local n_images = images["n_images"]

      -- interpolate to the img variable
      img[1] = md.MDStep{R=initial}
      img[n_images + 2] = md.MDStep{R=final}
      dR = (final - initial) / (n_images + 1)
      for i = 2, n_images + 1 do
	 img[i] = md.MDStep{R=initial + dR * (i - 1)}
      end

   else

      -- Copy reference
      img = images

   end

   -- Copy all images over
   local size_img = #img[1].R
   for i = 1, #img do
      self[i-1] = img[i]
      if #img[i].R ~= size_img then
	 error("NEB: images does not have same size of geometries!")
      end
   end


   -- store the number of images (without the initial and final)
   self.n_images = #img - 2

   -- This is _bad_ practice, however,
   -- the middleclass system does not easily enable overwriting
   -- the __index function (because it uses it)
   self.initial = img[1]
   self.final = img[#img]

   -- an integer that describes when the climbing image
   -- may be used, make large enough to never set it
   local cl = tbl.climbing or 5
   if cl == false then
      self._climbing = 1000000000000
   elseif cl == true then
      -- We use the default value
      self._climbing = 5
   else
      -- Counter for climbing
      self._climbing = cl
   end

   -- Set the climbing energy tolerance
   self.climbing_tol = tbl.climbing_tol or 0.005 -- if the input is in eV/Ang this is 5 meV

   self.niter = 0

   -- One should also attach the spring-constant
   -- It currently defaults to 5
   local kl = tbl.k or 5.
   if type(kl) == "table" then
      self.k = kl
   else
      self.k = setmetatable({},
			    {
			       __index = function(t, k)
				  return kl
			       end
			    })
   end
   
   self:init_files()

end

-- Simple wrapper for checking the image number
function NEB:_check_image(image, all)
   local all = all or false
   if all then
      if image < 0 or self.n_images + 1 < image then
	 error("NEB: requesting a non-existing image!")
      end
   else
      if image < 1 or self.n_images < image then
	 error("NEB: requesting a non-existing image!")
      end
   end
end


--- Return the coordinate difference between two images
-- @int img1 the first image
-- @int img2 the second image
-- @return `NEB[img2].R - NEB[img1].R`
function NEB:dR(img1, img2)
   self:_check_image(img1, true)
   self:_check_image(img2, true)

   -- This function assumes the reference
   -- image is checked in the parent function

   return self[img2].R - self[img1].R

end

--- Calculate the tangent of a given image
-- @int image the image to calculate the tangent of
-- @return tangent force
function NEB:tangent(image)
   self:_check_image(image)

   -- Determine energies of relevant images
   local E_prev = self[image-1].E
   local E_this = self[image].E
   local E_next = self[image+1].E

   -- Determine position differences
   local dR_prev = self:dR(image-1, image)
   local dR_next = self:dR(image, image+1)

   -- Returned value
   local tangent

   -- Determine relevant energy scenario
   if E_next > E_this and E_this > E_prev then
      
      tangent = dR_next

   elseif E_next < E_this and E_this < E_prev then
      
      tangent = dR_prev

   else
      
      -- We are at extremum, so mix
      local dEmax = m.max( m.abs(E_next - E_this), m.abs(E_prev - E_this) )
      local dEmin = m.min( m.abs(E_next - E_this), m.abs(E_prev - E_this) )
      
      if E_next > E_prev then
	 tangent = dR_next * dEmax + dR_prev * dEmin
      else
	 tangent = dR_next * dEmin + dR_prev * dEmax
      end
      
   end

   -- At this point we have a tangent,
   -- now normalize and return it
   return tangent / tangent:norm(0)

end


--- Determine whether the queried image is climbing
-- @int image image queried
-- @return true if the image is climbing
function NEB:climbing(image)
   self:_check_image(image)
   
   -- Determine energies of relevant images
   local E_prev = self[image-1].E
   local E_this = self[image  ].E
   local E_next = self[image+1].E

   -- Assert the tolerance is taken into consideration
   return (E_this - E_prev > self.climbing_tol) and
       (E_this - E_next > self.climbing_tol)
   
end

--- Calculate the spring force of a given image
-- @int image the image to calculate the spring force of
-- @return spring force
function NEB:spring_force(image)
   self:_check_image(image)
   
   -- Determine position norms
   local dR_prev = self:dR(image-1, image):norm(0)
   local dR_next = self:dR(image, image+1):norm(0)
   
   -- Set spring force as F = k (R1-R2) * tangent
   return self.k[image] * (dR_next - dR_prev) * self:tangent(image)
   
end


--- Calculate the perpendicular force of a given image
-- @int image the image to calculate the perpendicular force of
-- @return perpendicular force
function NEB:perpendicular_force(image)
   self:_check_image(image)

   -- Subtract the force projected onto the tangent to get the perpendicular force
   local P = self[image].F:project(self:tangent(image))
   return self[image].F - P

end

--- Calculate the curvature of the force with regards to the tangent
-- @int image the image to calculate the curvature of
-- @return curvature
function NEB:curvature(image)
   self:_check_image(image)

   local tangent = self:tangent(image)

   -- Return the scalar projection of F onto the tangent (in this case the
   -- tangent is already normalized so no need to no a normalization)
   return self[image].F:flatdot(tangent)
   
end

--- Calculate the resulting NEB force of a given image
-- @int image the image to calculate the NEB force of
-- @return NEB force
function NEB:neb_force(image)
   self:_check_image(image)

   local NEB_F

   -- Only run Climbing image after a certain amount of steps (robustness)
   -- Typically this number is 5.
   if self.niter > self._climbing and self:climbing(image) then
      local F = self[image].F
      NEB_F = F - 2 * F:project( self:tangent(image) )
   else
      NEB_F = self:perpendicular_force(image) + self:spring_force(image)
   end

   return NEB_F

end

--- Query the current coordinates of an image
-- @int image the image
-- @return coordinates
function NEB:R(image)
   self:_check_image(image, true)

   return NEB[image].R
end

--- Query the current NEB force and optionally write out the current step information
-- Calculates the NEB force for the current image and optionally store
-- the current image information to the files.
--
-- The generated files are:
--
-- - `NEB.<image>.R`
--   containing the relaxation steps of image `<image>`
-- - `NEB.<image>.F`
--   containing the force of image `<image>`
-- - `NEB.<image>.F.P`
--   containing the perpendicular force of image `<image>`
-- - `NEB.<image>.F.S`
--   containing the spring force of image `<image>`
-- - `NEB.<image>.F.NEB`
--   containing the NEB force of image `<image>` (equivalent to the returned force)
-- - `NEB.<image>.T`
--   containing the tangent of image `<image>`
-- - `NEB.<image>.dR_prev`
--   containing the reaction coordinate against the previous image
-- - `NEB.<image>.dR_next`
--   containing the reaction coordinate against the next image
--
-- All files contains a consecutive list of the values for each iteration.
--
-- @int image the image
-- @bool IO whether or not the current step should be stored
-- @return force
function NEB:force(image, IO)
   self:_check_image(image)

   if image == 1 then
      -- Increment step-counter
      self.niter = self.niter + 1
   end

   local NEB_F = self:neb_force(image)

   -- Things I want to output in files as control (all in 3xN format)
   if IO then
      local f

      -- Current coordinates (ie .R)
      f = io.open( ("NEB.%d.R"):format(image), "a")
      self[image].R:savetxt(f)
      f:close()

      -- Forces before (ie .F)
      f = io.open( ("NEB.%d.F"):format(image), "a")
      self[image].F:savetxt(f)
      f:close()

      -- Perpendicular force
      f = io.open( ("NEB.%d.F.P"):format(image), "a")
      self:perpendicular_force(image):savetxt(f)
      f:close()
      
      -- Spring force
      f = io.open( ("NEB.%d.F.S"):format(image), "a")
      self:spring_force(image):savetxt(f)
      f:close()

      -- NEB Force
      f = io.open( ("NEB.%d.F.NEB"):format(image), "a")
      NEB_F:savetxt(f)
      f:close()

      -- Tangent
      f = io.open( ("NEB.%d.T"):format(image), "a")
      self:tangent(image):savetxt(f)
      f:close()

      -- dR - previous reaction coordinate
      f = io.open( ("NEB.%d.dR_prev"):format(image), "a")
      self:dR(image-1, image):savetxt(f)
      f:close()

      -- dR - next reaction coordinate
      f = io.open( ("NEB.%d.dR_next"):format(image), "a")
      self:dR(image, image+1):savetxt(f)
      f:close()

   end

   -- Fake return to test
   return NEB_F
   
end

--- Store the current step of the NEB iteration with the appropriate results
-- Append to the file NEB.results the current NEB image step results.
-- The stored data consists of the following columns:
--
-- 1. Image number
-- 2. Accummulated reaction coordinate (the 1D-norm of `NEB:dR(i-1, i)`)
-- 3. Total energy of current iteration
-- 4. Total energy difference from initial image
-- 5. Image curvature
-- 6. Maximum NEB force exerted on any given atom.
--
-- @bool IO whether or not the results should be written
function NEB:save(IO)

   -- If we should not do IO, return immediately
   if not IO then
      return
   end

   -- local E0
   local E0 = self[0].E

   -- Now setup the matrix to write the NEB-results
   local dat = array.Array( self.n_images + 2, 6)
   for i = 0, self.n_images + 1 do

      local row = dat[i+1]
      -- image number (0 for initial, n_images + 1 for final)
      row[1] = i
      -- Accumulated reaction coordinate
      if i == 0 then
	 row[2] = 0.
      else
	 row[2] = dat[i][2] + self:dR(i-1, i):norm(0)
      end
      -- Total energy of current iteration
      row[3] = self[i].E
      -- Energy difference from initial image
      row[4] = self[i].E - E0
      -- Image curvature
      if i == 0 or i == self.n_images + 1 then
	 row[5] = 0.
      else
	 row[5] = self:curvature(i)
      end
      -- Vector-norm of maximum force of the NEB-force
      if i == 0 or i == self.n_images + 1 then
	 row[6] = 0.
      else
	 row[6] = self:neb_force(i):norm():max()
      end

   end

   local f = io.open("NEB.results", "a")
   dat:savetxt(f)
   f:close()

end

--- Initialize all files that will be written to
function NEB:init_files()
   
   -- We clean all image data for a new run
   local function new_file(fname, ...)
      local f = io.open(fname, 'w')
      local a = {...}
      for _, v in pairs(a) do
	 f:write("# " .. v .. "\n")
      end
      f:close()
   end

   new_file("NEB.results", "NEB results file",
	    "Image reaction-coordinate Energy E-diff Curvature F-max(atom)")
   
   for img = 1, self.n_images do
      new_file( ("NEB.%d.R"):format(img), "Coordinates")
      new_file( ("NEB.%d.F"):format(img), "Constrained force")
      new_file( ("NEB.%d.F.P"):format(img), "Perpendicular force")
      new_file( ("NEB.%d.F.S"):format(img), "Spring force")
      new_file( ("NEB.%d.F.NEB"):format(img), "Resulting NEB force")
      new_file( ("NEB.%d.T"):format(img), "NEB tangent")
      new_file( ("NEB.%d.dR_prev"):format(img), "Reaction distance (previous)")
      new_file( ("NEB.%d.dR_next"):format(img), "Reaction distance (next)")
   end

end


--- Print to screen some information regarding the NEB algorithm
function NEB:info()

   print("NEB has " .. self.n_images)
   print("NEB uses climbing after " .. self._climbing .. " steps")
   local tmp = array.Array( self.n_images + 1 )
   tmp[1] = self:dR(0, 1):norm(0)
   for i = 2, self.n_images + 1 do
      tmp[i] = tmp[i-1] + self:dR(i-1, i):norm(0)
   end
   print("NEB reaction coordinates: ")
   print(tostring(tmp))
   local tmp = array.Array( self.n_images )
   for i = 1, self.n_images do
      tmp[i] = self.k[i]
   end
   print("NEB spring constant: ")
   print(tostring(tmp))

end

return NEB
