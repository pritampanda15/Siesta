# The tutorial has been prepared to calculate Raman off-resonant activity calculator using VASP as a back-end.
This tutorial has been referred from https://github.com/raman-sc/VASP.

# Slurm script on HPC\Script to run RAMAN
Before running the script:
Do the following in the terminal:
Load Python 2.7.14-anaconda

```
export VASP_RAMAN_RUN="mpprun /software/sse/manual/vasp/5.4.4.16052018/nsc1/vasp_std"
export VASP_RAMAN_PARAMS="01_24_2_0.01"
```
```
#!/bin/bash
#SBATCH --time=05:00:00
#SBATCH  -N 4
#SBATCH --account=snic2019-1-25
#SBATCH -J Raman
#SBATCH --exclusive
#SBATCH --ntasks-per-node=32
ulimit -s unlimited 
export VASP_RAMAN_RUN="mpprun /software/sse/manual/vasp/5.4.4.16052018/nsc1/vasp_std"
export VASP_RAMAN_PARAMS="01_24_2_0.01"
module load Python/2.7.14-anaconda-5.0.1-nsc1
python vasp_raman.py > vasp_raman.out

#For graph
#Broaden.py
python broaden.py vasp_ramn.dat
```

Reference
@book{vasp_raman_py,
year = "2013",
author = "A. Fonari and S. Stauffer",
title = "vasp_raman.py",
publisher = "https://github.com/raman-sc/VASP/"
}
