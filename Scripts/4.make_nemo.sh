#!/bin/bash
# Set up and compile CS1.5 on Cirrus.
# Adapted from setup_CS1.5_Cirrus. Run from the Scripts directory.
set -e

source ./1.make_path.sh
REV=13653

#################################################################################################
# Load the GNU modules, matching the existing XIOS build
#################################################################################################

module load PrgEnv-gnu
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
module load subversion/1.14.2

export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

#################################################################################################
# Check out NEMO 4.0.4 from the SVN repository
#################################################################################################

# Comment out the checkout command when rebuilding an existing installation.
svn checkout -r$REV https://svn-mirror.nemo-ocean.eu/NEMO/releases/r4.0/r4.0.4 $NEMO

#################################################################################################
# Copy the architecture files and set the path to the existing XIOS installation
#################################################################################################

cd $NEMO
cp $gituhb_download/CS1.5_NEMO_support/NEMO_arch/* ./arch/
sed -i "s?XXX_XIOS_DIR_XXX?$XIOS_DIR?g" ./arch/arch-$HPC_TARG.fcm

#################################################################################################
# Set up the configuration directory
#################################################################################################

mkdir -p $CONFIG_DIR

# Register the configuration, 
touch $CDIR/work_cfgs.txt
echo "$CONFIG OCE" >> $CDIR/work_cfgs.txt

#################################################################################################
# Copy the local source changes and CPP keys, then compile NEMO
#################################################################################################

mkdir -p $CONFIG_DIR/MY_SRC
cp $gituhb_download/MY_SRC/* $CONFIG_DIR/MY_SRC/
cp $gituhb_download/CS1.5_NEMO_support/cpp_co9-amm7.fcm $CONFIG_DIR/cpp_$CONFIG.fcm

cd $NEMO
./makenemo -m $HPC_TARG -r $CONFIG -j 16

test -x $CONFIG_DIR/BLD/bin/nemo.exe

echo "Executable is $CONFIG_DIR/BLD/bin/nemo.exe"

cd $WDIR
