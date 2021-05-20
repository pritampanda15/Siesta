#!/bin/bash
# ===========================================================#
# 	**** Script for I-V plot  ****           	      # 
#============================================================#
# run this script for electrode using command                #
#	 $ sh get_IV_curve_script.sh                         #
# The calculation should complete in few miniuts             #
#=============================================================
# Author: Mohan L Verma, Computational Nanomaterial          #  
# Research lab, Department of Applied Physics, FET,          #
# SSGI, Shri Shanakaracharya Technical Campus-Bhilai         # 
# (Chhattisgarh)  INDIA, www.drmlv.in                        #
#=============================================================
# Dont forget to give feedback : drmohanlv@gmail.com         #
#          March 31     ver:4.1-b4    year: 2021             #
#=============================================================
> IV.dat
for i in `seq -w 0.0 0.1 1.5`  
 
do
cd $i

IV_Curve=`grep 'Left -> Right, V \[V] / I \[A]:' tbt.out | tail -1 | awk '{print $12}'`
echo $i '   '$IV_Curve >> ../IV.dat
cd ../
done
sed -i '1 i\#========================================================#' IV.dat
sed -i '2 i\#    This data is extracted using get_IV_curve_script    #' IV.dat
sed -i '3 i\#Author : Dr Mohan L Verma, Computational Nanomaterial   #' IV.dat
sed -i '4 i\#Research lab, Department of Applied Physics, FET,  SSGI #' IV.dat
sed -i '5 i\#Shri Shanakaracharya Technical Campus-Bhilai (CG) INDIA #' IV.dat
sed -i '6 i\#========================================================#' IV.dat
xmgrace IV.dat &

