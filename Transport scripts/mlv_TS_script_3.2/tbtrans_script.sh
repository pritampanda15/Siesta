#!/bin/bash
# ===========================================================#
# 	**** Script for tbtrans  run ****        	     # 
#============================================================#
# It is expected that in ~/bin dir  the  binary/exe file of  #
# tbtrans.						     #
# In presence of proper *.psf file for corresponding elements #
# run this script for electrode using command                #
#	 $ sh tbtrans_script.sh                              #
# The calculation may take long time depending on size of    #
# system and number of nodes(in parallel run )               #
# Author: Mohan L Verma, Computational Nanomaterial          #  
# Research lab, Department of Applied Physics, FET,          #
# SSGI, Shri Shanakaracharya Technical Campus-Junwani        # 
# Bhilai(Chhattisgarh)  INDIA                                #
# Sept 29    ver: 0.1   year: 2014                           #
#------------------------------------------------------------#


for i in `seq -w 0.0 0.1 1.8`  
do

cd $i

./tbtrans < scat.fdf | tee tbt.out  #  &  # if you have more than 19 cpu-core, remove the first # on this line !

cd ..

done



