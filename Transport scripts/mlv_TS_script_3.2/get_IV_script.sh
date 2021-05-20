
#!/bin/bash
# ===========================================================#
# 	**** Script for I-V plot  ****           	     # 
#============================================================#
# run this script for electrode using command                #
#	 $ sh get_IV_script.sh                               #
# The calculation should complete in few miniuts             #
# Author: Mohan L Verma, Computational Nanomaterial          #  
# Research lab, Department of Applied Physics, FET,          #
# SSGI, Shri Shanakaracharya Technical Campus-Junwani        # 
# Bhilai(Chhattisgarh)  INDIA                                #
# Sept 29    ver: 0.1   year: 2014                           #
#------------------------------------------------------------#


> IV.dat

for i in `seq -w 0.0 0.1 1.8`  
do

cd $i

cat tbt.out | grep " Voltage, Current(A) =" | awk '{print $4"   "$5}' >> ../IV.dat

cd ..

done


xmgrace IV.dat &
