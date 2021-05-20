#!/bin/bash
# ===========================================================#
# One  small script to copy data from scat.AVTRANS generated # 
# after tbtrans run. This will generate three data files in  #
# corresponding directory for : 			     #
# 1) Energy vs Transmitance plot as EvsT.dat                 #
# 2) Energy vs Total density of states plot as EvsTD.dat  and# 
# 3) Energy vs projected  density of states plot as EvsPD.dat#  
# Author: Mohan L Verma, Computational Nanomaterial          #  
# Research lab, Department of Applied Physics, FET,          #
# SSGI, Shri Shanakaracharya Technical Campus-Junwani        # 
# Bhilai(Chhattisgarh)  INDIA                                #
# Sept 29    ver: 0.1   year: 2014                             #
#------------------------------------------------------------#

for i in `seq -w 0.0 0.1 1.8`  
do

cd $i

cat scat.AVTRANS

awk '{print $1"    "$2}' scat.AVTRANS >> EvsT.dat
awk '{print $1"   "$3}' scat.AVTRANS >> EvsTD.dat
awk '{print $1"   "$4}' scat.AVTRANS >> EvsPD.dat

cd ..

done 

#==============================================================#

 
