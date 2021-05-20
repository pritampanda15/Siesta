#!/bin/bash
# ===========================================================#
# 	**** Script for electrode run ****        	     # 
#============================================================#
# Please follow the steps : 				     #
# 1)make the electrode input file elec.fdf  for your system  #
# (don't change the name of file as  well as system name).   #
# It is expected that in ~/bin dir  the  binary/exe file of  #
# transiesta.						     #
# In presence of proper *.psf file for corresponding elements #
# run this script for electrode using command                #
#	 $ sh elec_script.sh                                 #
# The calculation should complete in a few minutes and will  #
#  generate a elec.TSHS file.		        	     #
# Author: Mohan L Verma, Computational Nanomaterial          #  
# Research lab, Department of Applied Physics, FET,          #
# SSGI, Shri Shanakaracharya Technical Campus-Junwani        # 
# Bhilai(Chhattisgarh)  INDIA                                #
# Sept 29    ver: 0.1   year: 2014                           #
#------------------------------------------------------------#
 
echo "Electrode Calculation"

mkdir Elec

cd Elec

cp ../elec.fdf .
cp ../*.psf .
cp ~/bin/transiesta .
cp ~/bin/gnubands .


./transiesta < elec.fdf | tee elec.out 


 
cp elec.out  ../ts_elec.out
#
# Go back to base directory


#
cd ..

 
