
#!/bin/bash
# ===========================================================#
# 	**** Script for copy data  ****        	             # 
#============================================================#
# Please follow the steps : 				     #
# 1) modify this script file as per requirement of your      #
# (don't change the name of file as  well as system name).   #
# It is expected that in ~/bin dir  the  binary/exe file of  #
# transiesta.						     #
# In presence of proper *.psf file for corresponding elements #
# run this script for electrode using command                #
#	 $ sh copy-data-files.sh                             #
# This will copy all required file in a folder named as data #
# Author: Mohan L Verma, Computational Nanomaterial          #  
# Research lab, Department of Applied Physics, FET,          #
# SSGI, Shri Shanakaracharya Technical Campus-Junwani        # 
# Bhilai(Chhattisgarh)  INDIA                                #
# Nov 05    ver: 0.1   year: 2014                            #
#------------------------------------------------------------#

mkdir data 

for i in `seq -w 0.0 0.1 1.8`  
do

cd $i

mkdir data-$i 

cd data-$i 


cp ../scat.fdf .
cp ../scat.out .
cp ../scat.xyz .
cp ../scat.EIG .
cp ../scat.XV .
cp ../tbt.out  .
cp ../scat.AVTRANS .
cp ../*.dat .
cp ../scat.RHO .
cd ..



cp -r data-$i  ../data/

 

cd ..

cd data 
cp  ../IV.dat .

cd ..

done


#xmgrace IV.dat &
