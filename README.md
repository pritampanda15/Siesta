# Siesta
SIESTA is a density-functional code able to perform efficient electronic structure calculations and ab initio molecular dynamics  simulations of molecules and solids.

FDF (Input) files for relaxation, PDOS and Denchar calculations in SIESTA 4.0.2 version as well as 4.1-b4 and PSML supported version (https://launchpad.net/siesta/psml-support) are as follows:
a. complete_fdf ----> A complete fdf file for various strategical electronic structure calculations
b. relax.fdf ------> For relaxation;
c. dos.fdf --------> For PDOS calculation;
d. denchar.fdf ----> For denchar calculations 3D/2D.

An additional fdf input file with all the tags for different strategies are provided in complete_fdf file. Calculations like bandstructure, phonons, fermi surface, LDA+U tags have been defined. 

Before changing the parameters mentioned in the input files (marked as XXXXX), do convergence test especially for meshcutoff, kpoints, SCF.DM.Tolerance, Electronic Temperature.

Recommended Criteria's for fully relativistic calculations during SCF cycles:
1. High number of kpoints
2. Low electronic temperature
3. Extremely small DM. Tolerance
4. High MeshCutoff

Recommended tutorials:
https://personales.unican.es/junqueraj/JavierJunquera_files/Metodos/Theory-session.html
https://personales.unican.es/junqueraj/JavierJunquera_files/Metodos/Hands-on-session.html
https://departments.icmab.es/leem/siesta/Documentation/Tutorials/index.html
https://departments.icmab.es/leem/siesta/Documentation/Tutorials/Barcelona-2007/Basic-Execution.pdf
https://departments.icmab.es/leem/siesta/Documentation/Tutorials/www.niees.ac.uk/events/siesta/siesta_files/Intro-1.pdf
http://www.training.prace-ri.eu/uploads/tx_pracetmo/Tutorial_-_The_Siesta_Code.pdf

Access to psuedopotentials:
http://nninc.cnf.cornell.edu/ (PSF format)
https://departments.icmab.es/leem/siesta/Databases/Pseudopotentials/periodictable-intro.html (PSF format)
http://www.pseudo-dojo.org/ (PSML format)

Citations
1. Phys. Rev. B 53, 10441, (1996)
2. Int. J. Quantum Chem., 65, 453 (1997)
3. J. Phys.: Condens. Matt. 14, 2745-2779 (2002)
4. J. Phys.: Condens. Matter 20, 064208 (2008)
5. Computer Physics Communications 226, 39-54 (2018), 10.1016/j.cpc.2018.01.012 arxiv preprint
6. Computer Physics Communications 227, 51-71 (2018), 10.1016/j.cpc.2018.02.011

Cheers!!!
Happy DFTing.
