# NEB-Siesta
How to compile siesta using LUA and Flook library and run NEB calculations

1. Install Flos library: https://docs.siesta-project.org/projects/siesta/en/latest/how-to/others/flos.html#how-to-flos
2. Install Flook library (Refer flook.zip): https://flos.readthedocs.io/en/latest/0-setting-up-flos.html#enabling-siesta-lua-interface-flook
3. Use ESL-Bundle library files (Refer ESL-bundle): https://github.com/ElectronicStructureLibrary/esl-bundle
4. Install Siesta 4.1.5 using arch make: https://gitlab.com/siesta-project/siesta/-/releases/v4.1.5

In order to run the neb_plot.py ensure that you have run this command  grep NEB: "your input file" and save it as neb_data.txt
