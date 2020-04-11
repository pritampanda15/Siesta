#!/bin/bash

# ==================================================== #
# Script: Full relaxation of ZnO molecule              #
#------------------------------------------------------#
# The for represets the mesh-cutoff  from 50 to 500    #  
# run this script using command                        #
#  sh script_cutoff.sh                                 #
# this will creat 10 folders with complete siesta run  #
#          #
#===================================================== #
# With the best parameters (MeshCutoff, Kpoint         #
# and lattice constant) we will RELAX the              #
# structure.                                           #
# ---------------------------------------------------- #
 
# ============================================== *
# The script will run ONE input of AgImol        *
#                                                *
# Type of calculation: CG                        *
#                                                *   
# Objective: final relaxed structure             *
#                                                *
# Parameter otimized: Full realxation            *
#                                                * 
# How can I run the script                       *
#                                                *
#    sh script_final_opt.sh                            *
#                                                *
# For visualize in real time the output          *
#                                                *
#    tail -f outputSiesta.txt                    *
#                                                *
# ============================================== *
#                                                   *
# Warning: You need change all optimized parameters *
#                                                   * 
# 1) Mesh Cutoff                                    * 
#                                                   * 
# MeshCutoff        XXXXXXXXXXXXXX Ry               *
#                                                   * 
# change to                                         *
#                                                   * 
# MeshCutoff        optimized value Ry              *
#                                                   *
# 2) Kpoint                                         *
#                                                   *
# %block kgrid_Monkhorst_Pack                       *                      
# YY   0   0     0.0                                *
# 0   YY   0     0.0                                *
# 0   0   YY    0.0                                 *
#%endblock kgrid_Monkhorst_Pack                     *
#                                                   *
# 3) Lattice Constant (Lz_opt)                      *
#                                                   *
# LatticeConstant   ZZZ Ang                         *
#                                                   *
# %block LatticeVectors                             *
#    1.00    0.00    0.00                           *
#     0.00   1.00    0.00                           *
#     0.00    0.00   1.00                           *
# %endblock LatticeVectors                          *
#                                                   * 
# ================================================= *

siesta <zno.fdf | tee relax.out
