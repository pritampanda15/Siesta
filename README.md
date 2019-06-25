# Siesta
SIESTA is a density-functional code able to perform efficient electronic structure calculations and ab initio molecular dynamics  simulations of molecules and solids.

FDF (Input) files for relaxation, PDOS and Denchar calculations in SIESTA 4.0.2 version as well as 4.1-b4 and PSML supported version (https://launchpad.net/siesta/psml-support) are as follows:
a. complete_fdf ----> A complete fdf file for various strategical electronic structure calculations
b. relax.fdf ------> For relaxation;
c. dos.fdf --------> For PDOS calculation;
d. denchar.fdf ----> For denchar calculations 3D/2D.

An additional fdf input file with all the tags for different strategies are provided in complete_fdf file. Calculations like bandstructure, phonons, fermi surface, LDA+U tags have been defined. 

Check out my youtube tutorial videos:
https://www.youtube.com/watch?v=eofuNrCtUQU&t=43s
https://www.youtube.com/watch?v=B3HUvSkG55o&t=26s

Before changing the parameters mentioned in the input files (marked as XXXXX), do convergence test especially for meshcutoff, kpoints, SCF.DM.Tolerance, Electronic Temperature.

Recommended Criteria's for fully relativistic calculations during SCF cycles:
1. High number of kpoints
2. Low electronic temperature
3. Extremely small DM. Tolerance
4. High MeshCutoff

Siesta Utilities:You can find these utilities in Siesta/ Util folder:
Bands:     Tools for plotting band structures (including "fatbands")

CMLComp: Tools to use the information contained in the CML file
         produced by the program (by Toby White, Andrew Walker,
         and others)

Contour: grid2d: As Denchar but for any function defined in the 3D
         grid.  grid1d: Extracts a 1D line of data out of the 3D grid.
         Based on the 3D grid (by E. Artacho)

Contrib: Code contributed by Siesta users (expanding collection). See
	 the individual documentation materials.

COOP: Generation of COOP/COHP/PDOS curves for chemical analysis.
      Computation of data to generate "fatbands" plots.

Denchar: Produces 2D and 3D plots of charge and spin density, and of
         wave-functions. Uses the density matrix and basis orbital
         information (by J. Junquera and P. Ordejon).

DensityMatrix: Utilities to process and convert density-matrix files.

Eig2DOS:   Estimation of the Density of States from the .EIG file.
           (by E. Artacho and A. Garcia)

Gen-basis : Stand-alone program 'gen-basis' to generate basis sets and
            KB projectors, and 'ioncat' program for extraction of
            information from .ion files.

Grid: Utilities for the manipulation of grid files.

Grimme: Enable easy creation of the atomic potential block by reading
	the ChemicalSpecies block and printing out the relevant information.
	This makes it _very_ easy to create the correct units and quantities.
	(by N. Papior)

Helpers: Some helper scripts for aiding script generation.

HSX: Conversion tool between HS and HSX files (by A. Garcia)

JobList:   A suite of programs to generate and dispatch multiple
           SIESTA jobs with varying options (by J. Soler)

Macroave: Macroscopic averaging for interfaces and surfaces (by
	  J. Junquera)

MD: Some sample scripts for the extraction of some MD information from
    the output file (by A. Garcia)

MM_Examples: Force-field examples

MPI_test:    Tests to help diagonose the interface to MPI.

ON: Conversion of Order-N eigenstate to NetCDF file

Optical: Calculation of optical properties (by D. Sanchez-Portal)

Optimizer: General-purpose optimizer. Useful for basis-set and
	   pseudopotential optimization (by A. Garcia)

pdosxml: Utility to process the PDOS file (in XML format). (by
	 A. Garcia)

PEXSI: Utilites related to the output from PEXSI (by A. Garcia)

Plrho: Plots in 3D the electron density and other functions
       calculated by siesta (by Jose M. Soler)

Projections: Compute projections of electronic structure of a system
	     over the orbitals of a subsystem.

PyAtom: Python scripts for plotting and data extraction (by A. Garcia)

SCF: Python scripts for smaller stuff (by A. Garcia)

Scripting: Experimental scripting modules in Python (by A. Garcia)

sies2arc: Converts output coordinates to the arc movie format (by
	  J. Gale)

SiestaSubroutine: Code and examples of the driving of Siesta by an
                  external agent (by J. Soler and A. Garcia)

Sockets: Examples of the use of the f90 sockets interface (by M. Ceriotti)

SpPivot: A utility to create a pivoting table for the sparse
	 patterns in Siesta. Can create GRAPHVIZ output for easy
	 display of the sparsity pattern (by N. Papior)

STM/simple-stm:   Simple program for STM simulations (by P. Ordejon)

STM/ol-stm:  Ordejon-Lorente STM image simulator

TS: Contains several different utilities that are related to
    the NEGF code TranSiesta. (by N. Papior)
    See TS/README for details.

VCA: Utilities to help in Virtual-Crystal calculations (by A. Garcia)

Vibra: Package to compute phonon frequencies and modes (by P. Ordejon)

WFS: Utilities for wavefunction-file manipulation

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
