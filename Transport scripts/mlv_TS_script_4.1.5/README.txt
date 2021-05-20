# ===========================================================#
# (1)	**** Script for electrode run ****        	       # 
#============================================================#
# Please follow the steps : 				       #
# 1)make the electrode input file elec.fdf  for your system  #
# (don't change the name of file as  well as system name).   #
# It is expected that all the binaries exe are linked with   #
# /usr/local/bin   					       #
# In presence of proper *.psf file for corresponding elements#
# run this script for lectrode using command                 #  
#	 $ sh elec_script.sh                                 #
# The calculation should complete in a few minutes and will  #
#  generate a elec.TSHS file.		        	       #
#============================================================
# ===========================================================#
#  (2)	**** Script for scat and tbtrans run ****            #
#                     (for siesta-4.1.5)                     # 
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
# (Chhattisgarh)  INDIA, 490020 www.drmlv.in                 #
#=============================================================
# Dont forget to give feedback : drmohanlv@gmail.com         #
#          March 31     ver:4.1.5    year: 2021             #
#=============================================================
      If you find any problem with this example, feel free to inform/contact me in  drmohanlv@gmail.com

All the best  !

 

