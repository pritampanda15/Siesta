package = "flos"
version = "0.1-1"
source = {
   url = "https://github.com/siesta-project/flos",
   tag = "v0.1"
}
description = {
   summary = "A Lua library for linking with SIESTA",
   detailed = "This library enables optimization schemes created in Lua to be used together with SIESTA via the flook library, hence the same flo + SIESTA = flos. This enables scripting level languages to inter-act and develop new MD schemes, such as new geometry constraints, geometry relaxations, etc.",
   homepage = "https://github.com/siesta-project/flos",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.4"
}
build = {
   type = "builtin",
   modules = {
      flos = "flos/init.lua",
      ['flos.error'] = "flos/error.lua",
      ['flos.md'] = "flos/md/init.lua",
      ['flos.md.mdstep'] = "flos/md/mdstep.lua",
      ['flos.middleclass.middleclass'] = "flos/middleclass/middleclass.lua",
      ['flos.middleclass.performance.run'] = "flos/middleclass/performance/run.lua",
      ['flos.middleclass.performance.time'] = "flos/middleclass/performance/time.lua",
      ['flos.middleclass.spec.class_spec'] = "flos/middleclass/spec/class_spec.lua",
      ['flos.middleclass.spec.classes_spec'] = "flos/middleclass/spec/classes_spec.lua",
      ['flos.middleclass.spec.default_methods_spec'] = "flos/middleclass/spec/default_methods_spec.lua",
      ['flos.middleclass.spec.instances_spec'] = "flos/middleclass/spec/instances_spec.lua",
      ['flos.middleclass.spec.metamethods_lua_5_2'] = "flos/middleclass/spec/metamethods_lua_5_2.lua",
      ['flos.middleclass.spec.metamethods_lua_5_3'] = "flos/middleclass/spec/metamethods_lua_5_3.lua",
      ['flos.middleclass.spec.metamethods_spec'] = "flos/middleclass/spec/metamethods_spec.lua",
      ['flos.middleclass.spec.mixins_spec'] = "flos/middleclass/spec/mixins_spec.lua",
      ['flos.num'] = "flos/num/init.lua",
      ['flos.num.array'] = "flos/num/array.lua",
      ['flos.num.linalg'] = "flos/num/linalg/init.lua",
      ['flos.num.linalg.linalg'] = "flos/num/linalg/linalg.lua",
      ['flos.num.shape'] = "flos/num/shape.lua",
      ['flos.num.test'] = "flos/num/test.lua",
      ['flos.optima'] = "flos/optima/init.lua",
      ['flos.optima.base'] = "flos/optima/base.lua",
      ['flos.optima.cg'] = "flos/optima/cg.lua",
      ['flos.optima.fire'] = "flos/optima/fire.lua",
      ['flos.optima.lattice'] = "flos/optima/lattice.lua",
      ['flos.optima.lbfgs'] = "flos/optima/lbfgs.lua",
      ['flos.optima.line'] = "flos/optima/line.lua",
      ['flos.special'] = "flos/special/init.lua",
      ['flos.special.forcehessian'] = "flos/special/forcehessian.lua",
      ['flos.special.neb'] = "flos/special/neb.lua"
   }
}
