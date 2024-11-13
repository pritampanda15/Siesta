The `Siesta` repository, maintained by `pritampanda15`, provides a collection of FDF (Flexible Data Format) input files tailored for the SIESTA software package. SIESTA is a density-functional theory (DFT) code used for efficient electronic structure calculations and ab initio molecular dynamics simulations of molecules and solids. This repository offers input files compatible with SIESTA versions 4.0.2, 4.1-b4, and PSML-supported versions.

## Repository Structure

The repository is organized into several directories and files, each serving a specific purpose:

- **Hybrid_Potentials_and_Electric_field**: Contains input files and pseudopotentials for calculations involving hybrid potentials and electric fields. 

- **NEB-Siesta-main**: Includes scripts and input files for performing Nudged Elastic Band (NEB) calculations using SIESTA.

- **Pseudopotentials-master**: Offers a collection of pseudopotential files (.ion) for various elements, essential for SIESTA calculations. 

- **Raman-Phonon-VASP-master**: Provides scripts and input files for Raman and phonon calculations, particularly using VASP.

- **Transport scripts**: Contains scripts for transport calculations, including current scripts and electrode definitions. 

- **optimization scripts**: Offers scripts for optimizing structures and parameters within SIESTA calculations.

- **Bader.fdf**: An FDF file configured for Bader charge analysis.

- **complete_fdf.fdf**: A comprehensive FDF file encompassing various strategic electronic structure calculations.

- **denchar.fdf**: An FDF file set up for density charge (Denchar) calculations in 2D and 3D.

- **dos.fdf**: An FDF file designed for projected density of states (PDOS) calculations.

- **grid2cube.dat**: A data file potentially used for converting grid data to cube format.

- **relax.fdf**: An FDF file configured for structural relaxation calculations. 

- **wxDragon**: A directory that may contain scripts or tools related to wxDragon, a visualization tool for electronic structure calculations. 

# Siesta

**SIESTA** is a density-functional theory (DFT) code for performing efficient electronic structure calculations and ab initio molecular dynamics simulations of molecules and solids.

## Input Files (FDF) for SIESTA Calculations

The following Flexible Data Format (FDF) files are provided for various types of calculations compatible with SIESTA 4.0.2, 4.1-b4, and PSML-supported versions:

- **complete_fdf**: Comprehensive FDF file for various electronic structure calculations.
- **relax.fdf**: For relaxation calculations.
- **dos.fdf**: For projected density of states (PDOS) calculations.
- **denchar.fdf**: For charge density (Denchar) calculations in 3D/2D.

Additionally, the **complete_fdf** file includes tags for calculations such as band structure, phonons, Fermi surfaces, and LDA+U.

## Tutorial Videos

- [Introduction to SIESTA - Tutorial Part 1](https://www.youtube.com/watch?v=eofuNrCtUQU&t=43s)
- [Introduction to SIESTA - Tutorial Part 2](https://www.youtube.com/watch?v=B3HUvSkG55o&t=26s)

## Recommendations for SCF Convergence

When adjusting parameters (marked as `XXXXX` in input files), perform a convergence test, especially for:
1. **MeshCutoff** and **k-points**
2. **SCF.DM.Tolerance** and **Electronic Temperature**

**Recommended Settings for Fully Relativistic Calculations:**
- High k-points number
- Low electronic temperature
- Small DM tolerance
- High MeshCutoff

## Siesta Utilities

Available in the `Siesta/Util` folder:

- **Bands**: Plotting band structures, including "fatbands."
- **CMLComp**: Tools for handling data in CML format.
- **Contour**: Extracts and processes 1D and 2D data from 3D grids.
- **COOP**: For COOP/COHP/PDOS analysis.
- **Denchar**: Generates 2D/3D plots of charge density and wave-functions.
- **DensityMatrix**: Converts and processes density matrix files.
- **Eig2DOS**: Estimates DOS from `.EIG` files.
- **Gen-basis**: Generates basis sets and KB projectors.
- **Grid**: Grid file manipulation utilities.
- **Grimme**: Simplifies atomic potential generation.
- **Helpers**: Assorted helper scripts.
- **HSX**: Converts between HS and HSX files.
- **JobList**: Manages multiple SIESTA jobs.
- **Macroave**: Macroscopic averaging for interfaces.
- **MD**: Scripts for molecular dynamics data extraction.
- **MPI_test**: MPI interface diagnostics.
- **ON**: Converts Order-N eigenstate files to NetCDF.
- **Optical**: Optical properties calculations.
- **pdosxml**: Processes PDOS XML files.
- **PEXSI**: Utilities for PEXSI-related output.
- **Plrho**: 3D electron density plotting.
- **Projections**: Projects electronic structure onto subsystems.
- **PyAtom**: Python scripts for plotting and data extraction.
- **SCF**: Small utilities for SCF calculations.
- **sies2arc**: Converts coordinates to arc format.
- **SiestaSubroutine**: External agent driving examples.
- **Sockets**: F90 sockets interface examples.
- **STM**: STM image simulations.
- **TS**: Utilities for TranSiesta (NEGF code).
- **VCA**: Tools for Virtual-Crystal calculations.
- **Vibra**: Phonon frequency and mode calculations.
- **WFS**: Wavefunction file utilities.

## Recommended Tutorials

- [Siesta Theory Session](https://personales.unican.es/junqueraj/JavierJunquera_files/Metodos/Theory-session.html)
- [Siesta Hands-On Session](https://personales.unican.es/junqueraj/JavierJunquera_files/Metodos/Hands-on-session.html)
- [Siesta Tutorials](https://departments.icmab.es/leem/siesta/Documentation/Tutorials/index.html)

## Access to Pseudopotentials

- [PSF format (NNIN/Cornell)](https://nninc.cnf.cornell.edu/dd_search.php?frmxcprox=&frmxctype=&frmspclass=TM)
- [Simune SIESTA Pro](https://www.simuneatomistics.com/siesta-pro/siesta-pseudos-and-basis-database/)
- [PSML format (Pseudo Dojo)](http://www.pseudo-dojo.org/)

## Citations

1. Phys. Rev. B 53, 10441 (1996)
2. Int. J. Quantum Chem., 65, 453 (1997)
3. J. Phys.: Condens. Matt. 14, 2745-2779 (2002)
4. J. Phys.: Condens. Matter 20, 064208 (2008)
5. Computer Physics Communications 226, 39-54 (2018), 10.1016/j.cpc.2018.01.012
6. Computer Physics Communications 227, 51-71 (2018), 10.1016/j.cpc.2018.02.011

---

**Cheers and Happy DFTing!**


## Getting Started

To utilize the resources in this repository:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/pritampanda15/Siesta.git
   ```

2. **Navigate to the Desired Directory**:
   ```bash
   cd Siesta/Hybrid_Potentials_and_Electric_field
   ```

3. **Review and Modify Input Files**: Each FDF file contains parameters and settings for specific calculations. It's essential to adjust these parameters according to your system and research requirements. For instance, the `relax.fdf` file includes sections for system name, lattice vectors, atomic coordinates, and self-consistent field settings. 

4. **Run SIESTA Calculations**: After configuring the input files, execute your SIESTA calculations as per your computational setup.

## Contributing

Contributions to enhance this repository are welcome. To contribute:

1. **Fork the Repository**: Click on the 'Fork' button at the top right corner of the repository page.

2. **Create a New Branch**: For your feature or bug fix.
   ```bash
   git checkout -b feature-name
   ```

3. **Implement Changes**: Make the necessary modifications or additions.

4. **Commit Changes**:
   ```bash
   git commit -m "Description of changes"
   ```

5. **Push to Your Fork**:
   ```bash
   git push origin feature-name
   ```

6. **Submit a Pull Request**: Navigate to your forked repository on GitHub and click on 'New Pull Request'.

## License

The repository does not specify a license. It's advisable to contact the repository owner for clarification before using the code in commercial or open-source projects.

For more details, visit the [Siesta repository](https://github.com/pritampanda15/Siesta). 
