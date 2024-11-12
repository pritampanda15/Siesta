project='flos'
title='flos documentation'
description='A Lua library for geometry optimizations'
format='markdown'
backtick_references=true
readme='README.md'
not_luadoc='true'
plain=false
wrap=true
style='!pale'
dir='flos-doc'
kind_names={topic='Manual',script='Programs'}
examples = { 'examples',
}

-- Define an alias for the intrinsic used types
tparam_alias('Array','Array')

-- Optimizers
tparam_alias('Optimizer','Optimizer')
tparam_alias('CG','CG')
tparam_alias('FIRE','FIRE')
tparam_alias('LBFGS','LBFGS')
tparam_alias('Line','Line')


-- Special
tparam_alias('NEB','NEB')
tparam_alias('ForceHessian','ForceHessian')

