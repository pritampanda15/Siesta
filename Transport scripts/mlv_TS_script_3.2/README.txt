
These scripts have been prepraed for complete transiesta run in series compilation of transiesta and tbtrans.
In order to compile in series  Use following steps :

download siesta-trunk-462 from http://departments.icmab.es/leem/siesta/CodeAccess/Code/downloads.html

and extract it in home directory

now go to Obj dir and configure using : 

/home/drmohanlv/siesta-trunk-462/Obj/ sh ../Src/obj_setup.sh 

then 

/home/drmohanlv/siesta-trunk-462/Obj/ ../Src/configure 

finally compile transiesta  using 

/home/drmohanlv/siesta-trunk-462/Obj/ make transiesta 

this will generate a "transiesta" binary file in this directory. 

copy binary file to /home/drmohanlv/bin/  directory by 

/home/drmohanlv/siesta-trunk-462/Obj/ cp transiesta ~/bin

now for compilation of tbtrans go to 

/home/drmohanlv/siesta-trunk-462/Util/TBTrans_rep/

 and only type  make  this will generate "tbtrans" binary file for further use. 

copy binary file to /home/drmohanlv/bin/ directory by 

/home/drmohanlv/siesta-trunk-462/Obj/ cp tbtrans ~/bin
 
After above compilation of "transiesta" and "tbtrans" for transport proprties studies follow the steps : 

1-) make the electrode input file elec.fdf  for your system (don't change the name of file as  well as system name).

2-) It should be notes that in ~/bin dir  the  binary/exe file of transiesta  and tbtrans must be there.

4-) In presence of proper *.psf file for corresponding elements now run the first script for electrode using command  

	 $ sh elec_script.sh

Your calculation should complete in a few minutes and will generate a elec.TSHS file.

5-) Plot the band structure with your own method. 

6-) Now again modify bias_script.sh for your system and execute it  using 

	 $ sh bias_script.sh 

7-) Next we need to run tbtrans for each bias steps. Modify  tbtrans_script.sh and execute it.  

	$ sh tbtrans_script.sh 

8-) When you finish the previous step, execute 

	$ sh get_IV_script.sh 
This will genrate  I-V values  in I-V.dat file and you will have your I-V plot.

9-) Tbtrans generates scat.AVTRANS file in each folder. First column is Energy, the second one is transmission, the third one is TotDOS and the last one is PDOS.

10-) In order to  generate three data files in the corresponding directory for :

     	Energy vs Transmitance plot as EvsT.dat; 

     	Energy vs Total density of states plot as EvsTD.dat  and 

    	Energy vs projected  density of states plot as EvsPD.dat 

you need to run one more  script given in the same directory as getEvsX.sh which can be run using command : 

      $ sh getEvsX.sh  
 
If you want to creat data file containing required data for plot you can also use the fifth script i.e. copy-data-files.sh  using 
      $ sh copy-data-files.sh   
you can rename this data file as per the name of system and copy for further plotting.


      If you find any problem with this example, feel free to inform/contact me in  drmohanlv@gmail.com

All the best  !


Dr Mohan L Verma 

Computation Nanomaterial Research Lab
Department of Applied Physics
FET,SSGI, Shri Shankaracharya Technical Campus-Junwani Bhilai
Chhattisgarh (India) 490020


