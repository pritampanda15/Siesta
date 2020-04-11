#!/bin/bash

#======================================================#
# Script:mesh-cutoff optimization for ZnO molecule     #
# By Pritam Kumar Panda
# Dept. Of Physics and Astronomy
# Materials Theory Group
# Uppsala University 
#    
#------------------------------------------------------#
# The for represets the mesh-cutoff  from 50 to 500    #  
# run this script using cammand                        #
#  sh script_cutoff.sh                                 #
# this will creat 10 folders with complete siesta run  #
#                                  
#                              
#===================================================== #
mkdir cont   # read the comment at the end of this script.

for i in `seq -w 50 50 500`  
do


cp -r cont $i
cd $i
cp ../*.psf .
cp /Users/pritam/SIESTA/siesta-4.1-b4/Obj/siesta . #give the path for siesta excutive/binary file


cat > zno.fdf <<EOF

SystemName ZnO
SystemLabel ZnO

NumberOfAtoms 5
NumberOfSpecies 2

%block Chemical_Species_label
1 30 Zn
2 8 O
%endblock Chemical_Species_label

LatticeConstant 1.0 Ang

%block LatticeVectors
 3.2490000000 0.0000000000 0.0000000000
 -1.6245000000 2.8137165369 0.0000000000
 0.0000000000 0.0000000000 5.2070000000
%endblock LatticeVectors


AtomicCoordinatesFormat Ang
%block  AtomicCoordinatesAndAtomicSpecies
1.6245 0.9379 5.2070 1
-0.0000 1.8758 2.6035 1
1.6245 0.9379 0.0000 1
-0.0000 1.8758 4.3999 2
1.6245 0.9379 1.7964 2
%endblock  AtomicCoordinatesAndAtomicSpecies
 
 
==================================================
==================================================
# K-points
#kgrid_cutoff        0  Ang

#%block kgrid_Monkhorst_Pack
#1   0   0   0.0
#0   1   0   0.0
#0   0   1   0.0
#%endblock kgrid_Monkhorst_Pack

 
#%block GeometryConstraints
#position from  1 to  180
#%endblock GeometryConstraints

PAO.BasisSize     DZP
PAO.EnergyShift   0.03 eV
MD.TypeOfRun      CG
MaxSCFIterations  400
MD.NumCGsteps     0
MD.MaxForceTol    0.005  eV/Ang
MeshCutoff        $i Ry
DM.MixingWeight   0.02
DM.NumberPulay   3
WriteCoorXmol   .true.
WriteMullikenPop    1
XC.functional       GGA
XC.authors          PBE
SolutionMethod  diagon
ElectronicTemperature  25.86 meV
SaveRho        .true.


#UseSaveData     true
#DM.UseSaveDM    true
#MD.UseSaveXV    true
#MD.UseSaveCG    true




EOF

./siesta < zno.fdf | tee  siesta.out 


cd ..
rm -rf cont 
mkdir cont

cp   ./$i/scat.DM  cont  # copy these files for continuation of the next step.



done

