#!/bin/bash
# Compile XIOS3 on Cirrus. Run from the Scripts directory.
set -e   #stops the script when a command fails.

# Load paths.
source ./1.make_path.sh

# Load the GNU compiler and parallel NetCDF/HDF5 libraries.
module load PrgEnv-gnu
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel

# Copy the shared XIOS tree, including the files behind symbolic links.
cp -rL /epccfs/n01/shared/xios3/. $XIOS_DIR/

cd $XIOS_DIR

# Prepare the Cirrus GNU compiler files.
cp arch/arch-X86_ARCHER2-Gnu.fcm arch/arch-X86_CIRRUS-Gnu.fcm
cp arch/arch-X86_ARCHER2-Gnu.path arch/arch-X86_CIRRUS-Gnu.path
echo '# Use the modules loaded above.' > arch/arch-X86_CIRRUS-Gnu.env
sed -i 's/ -lmpichf90//g' arch/arch-X86_CIRRUS-Gnu.fcm

# Compile XIOS.
./make_xios --prod --arch X86_CIRRUS-Gnu --netcdf_lib netcdf4_par --job 16 --full

# Check the build outputs.
test -s lib/libxios.a
test -x bin/xios_server.exe
echo "Executable is $XIOS_DIR/bin/xios_server.exe"

cd $WDIR
