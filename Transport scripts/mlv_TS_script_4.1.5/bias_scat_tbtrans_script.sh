#!/bin/bash
# ===========================================================#
# 	**** Script for scat and tbtrans run ****            #
#                     (for siesta-4.1b4)                     # 
#============================================================#
# Please follow the steps : 				       #
# 1) modify this script file as per requirement of your      #
# (don't change the name of file as  well as system name).   #
# It is expected that all the binaries exe are linked with   #
# /usr/local/bin   					       #
# In presence of proper *.psf file for corresponding elements#
# run this script for transiesta and tbtrans run using command#
#	 $ sh bias_script.sh                                 #
# The calculation may take long time depending on size of    #
# system and number of nodes(in parallel run).               #
# The Value of current will be given in tbt.out     	       #
#=============================================================
# Author: Mohan L Verma, Computational Nanomaterial          #  
# Research lab, Department of Applied Physics, FET,          #
# SSGI, Shri Shanakaracharya Technical Campus-Bhilai         # 
# (Chhattisgarh)  INDIA, www.drmlv.in                        #
#=============================================================
# Dont forget to give feedback : drmohanlv@gmail.com         #
#           Aug 07     ver:4.1-b4    year: 2020              #
ncpu=2    ##give the number of cores in your parallel system #
#=============================================================

cp ../Elec/elec.TSHS .   # copy TSHS file from step-1

mkdir cont   # read the comment at the end of this script.

for i in `seq -w 0.0 0.1 1.5`  
do


cp -r cont $i
cd $i
cp ../*.psf .
cp ../Elec/elec.TSHS .
 
cat > scat.fdf <<EOF


 
SystemName          scat
SystemLabel         scat

# ---------------------------------------------------------------------------
# Lattice
# ---------------------------------------------------------------------------

LatticeConstant             1.00 Ang

%block LatticeVectors
    10.000000      0.000000      0.000000
     0.000000      6.528462      0.000000
     0.000000      0.000000     38.495728
%endblock LatticeVectors

# ---------------------------------------------------------------------------
# Species and Atoms
# ---------------------------------------------------------------------------

NumberOfSpecies        1
NumberOfAtoms         36

%block ChemicalSpeciesLabel
  1  14  Si
%endblock ChemicalSpeciesLabel

# ---------------------------------------------------------------------------
# Atomic Coordinates
# ---------------------------------------------------------------------------

AtomicCoordinatesFormat Ang

%block AtomicCoordinatesAndAtomicSpecies
5.00000	3.26423	1.15222	1
5.00000	1.15222	2.07405	1
5.00000	5.37625	2.07405	1
5.00000	1.15222	4.34190	1
5.00000	5.37625	4.34190	1
5.00000	3.26423	5.26374	1
5.00000	3.26423	7.56817	1
5.00000	1.15222	8.49001	1
5.00000	5.37625	8.49001	1
5.00000	1.15222	10.75786	1
5.00000	5.37625	10.75786	1
5.00000	3.26423	11.67970	1
5.00000	3.26423	13.98412	1
5.00000	1.15222	14.90596	1
5.00000	5.37625	14.90596	1
5.00000	1.15222	17.17381	1
5.00000	5.37625	17.17381	1
5.00000	3.26423	18.09565	1
5.00000	3.26423	20.40008	1
5.00000	1.15222	21.32192	1
5.00000	5.37625	21.32192	1
5.00000	1.15222	23.58977	1
5.00000	5.37625	23.58977	1
5.00000	3.26423	24.51160	1
5.00000	3.26423	26.81603	1
5.00000	1.15222	27.73787	1
5.00000	5.37625	27.73787	1
5.00000	1.15222	30.00572	1
5.00000	5.37625	30.00572	1
5.00000	3.26423	30.92756	1
5.00000	3.26423	33.23199	1
5.00000	1.15222	34.15383	1
5.00000	5.37625	34.15383	1
5.00000	1.15222	36.42168	1
5.00000	5.37625	36.42168	1
5.00000	3.26423	37.34351	1
%endblock AtomicCoordinatesAndAtomicSpecies
 
 
 
 
# K-points

%block kgrid_Monkhorst_Pack
1    0     0   0.0
0    5    0   0.0
0   0     1   0.0
%endblock kgrid_Monkhorst_Pack

PAO.BasisType         split
PAO.BasisSize         SZP
PAO.SplitNorm         0.15
PAO.EnergyShift       275 meV

MeshCutoff              250. Ry
XC.functional           GGA
XC.authors              PBE
SolutionMethod          transiesta

ElectronicTemperature   300 K
OccupationFunction      FD

MinSCFIterations       3
MaxSCFIterations       200
DM.MixingWeight        0.1
DM.Tolerance           0.0001
DM.NumberPulay         6
DM.UseSaveDM           .true.
DM.MixSCF1             .true.

MD.NumCGSteps 0

WriteMullikenPop                1
WriteForces                     T
SaveHS                          T


TS.Voltage   $i eV
 

%block TS.Atoms.Buffer
  atom from 1 to 6
  atom from -6 to -1
%endblock TS.Atoms.Buffer

%block TS.ChemPots
  Left
  Right
%endblock TS.ChemPots

%block TS.ChemPot.Left
  mu V/2
  contour.eq
    begin
      c-Left
      t-Left
    end
%endblock TS.ChemPot.Left
%block TS.ChemPot.Right
  mu -V/2
  contour.eq
    begin
      c-Right
      t-Right
    end
%endblock TS.ChemPot.Right

TS.Elecs.Bulk true
TS.Elecs.DM.Update cross-terms
TS.Elecs.GF.ReUse true
%block TS.Elecs
  Left
  Right
%endblock TS.Elecs

%block TS.Elec.Left
  HS ./elec.TSHS
  chem-pot Left
  semi-inf-dir -a3
  elec-pos begin 7
  used-atoms 6
%endblock TS.Elec.Left

%block TS.Elec.Right
  HS ./elec.TSHS
  chem-pot Right
  semi-inf-dir +a3
  elec-pos end -7
  used-atoms 6
%endblock TS.Elec.Right

TS.Contours.Eq.Pole    2.50000 eV
%block TS.Contour.c-Left
  part circle
   from  -40.00000 eV + V/2 to -10. kT + V/2
    points 25
     method g-legendre
%endblock TS.Contour.c-Left
%block TS.Contour.t-Left
  part tail
   from prev to inf
    points 10
     method g-fermi
%endblock TS.Contour.t-Left
%block TS.Contour.c-Right
  part circle
   from  -40.00000 eV - V/2 to -10. kT - V/2
    points 25
     method g-legendre
%endblock TS.Contour.c-Right
%block TS.Contour.t-Right
  part tail
   from prev to inf
    points 10
     method g-fermi
%endblock TS.Contour.t-Right

TS.Elecs.Eta    0.0001000000 eV
%block TS.Contours.nEq
  neq
%endblock TS.Contours.nEq
%block TS.Contour.nEq.neq
  part line
   from -|V|/2 - 5 kT to |V|/2 + 5 kT
    delta 0.01 eV
     method mid-rule
%endblock TS.Contour.nEq.neq



# TBtrans options

TBT.T.Eig 9
TBT.Elecs.Eta    0.0001000000 eV

%block TBT.Contours
  neq
%endblock TBT.Contours

%block TBT.Contour.neq
  part line
   from   -0.50000 eV to    0.50000 eV
    delta    0.00990 eV
     method mid-rule
%endblock TBT.Contour.neq

# It is advised to define a device region of
# particular interest
TBT.DOS.A T
# It is advised to define a device region of
# particular interest

EOF

mpirun -np $ncpu siesta  scat.fdf | tee  scat.out   # for scat run 


mpirun -np $ncpu tbtrans scat.fdf | tee  tbt.out    # for tbtrans run 


cd ..
rm -rf cont 
mkdir cont

cp  ./$i/scat.TSDE ./$i/scat.TSHS ./$i/scat.DM  cont  # copy these files for continuation of the next bias step.



done

