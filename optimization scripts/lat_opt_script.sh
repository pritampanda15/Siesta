#!/bin/bash


mkdir cont   # read the comment at the end of this script.

for i in `seq -w 2 0.25 5`  
do


cp -r cont $i
cd $i
cp ../*.psf .
cp /Users/pritam/SIESTA/siesta-4.1-b4/Obj/siesta . #give the path for siesta excutive/binary file


cat > zno.fdf <<EOF

SystemName ZnO 
SystemLabel    zno 

NumberOfSpecies 2
NumberOfAtoms   4

%block ChemicalSpeciesLabel
1   30  ZN
2   8   O
%endblock ChemicalSpeciesLabel
 
 
==================================================
==================================================
# K-points

%block kgrid_Monkhorst_Pack
10   0   0   0.0
0    10  0   0.0
0   0    10   0.0
%endblock kgrid_Monkhorst_Pack

LatticeConstant $i Ang


%block LatticeVectors 
    3.2530000210         0.0000000000         0.0000000000
 -1.6265000105         2.8171806567         0.0000000000
  0.0000000000         0.0000000000         5.2129998207
%endblock LatticeVectors

#%blockSuperCell
# 1   0   0
# 1   1   0
# 0   0   9
#%endblockSuperCell

AtomicCoordinatesFormat NotScaledCartesianAng
%block AtomicCoordinatesAndAtomicSpecies
   0.000000047         1.878120422         0.002856724  1
1.626500010         0.939060152         2.609356642  1
0.000000047         1.878120422         1.979699254  2
1.626500010         0.939060152         4.586199284  2
%endblock AtomicCoordinatesAndAtomicSpecies
 
#%block GeometryConstraints
#position from  1 to  180
#%endblock GeometryConstraints

PAO.BasisSize     DZP
PAO.EnergyShift   0.03 eV
MD.TypeOfRun      CG
MaxSCFIterations  400
MD.NumCGsteps     0
MD.MaxForceTol    0.005  eV/Ang
MeshCutoff        100 Ry
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

cp   ./$i/scat.DM  cont  

done