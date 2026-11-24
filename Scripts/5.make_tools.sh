#!/bin/bash
# Run from the Scripts directory.
set -e
source ./1.make_path.sh

###################################################################
#                 MAKE THE NEMO TOOLS
###################################################################

#------------------------------------------------------------------
# 1. Load the modules
#------------------------------------------------------------------

cd $WDIR

module load PrgEnv-gnu
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel

# NOT NEEDED ON CIRRUS
#export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

#------------------------------------------------------------------
# 2. Apply the patches
#------------------------------------------------------------------

# Copy the customized DOMAINcfg files, including wetting/drying changes.
cp $gituhb_download/CS1.5_NEMO_support/DOMAINcfg_src/dom_oce.f90 $TDIR/DOMAINcfg/src/dom_oce.f90
cp $gituhb_download/CS1.5_NEMO_support/DOMAINcfg_src/domain.f90 $TDIR/DOMAINcfg/src/domain.f90
cp $gituhb_download/CS1.5_NEMO_support/DOMAINcfg_src/domzgr.f90 $TDIR/DOMAINcfg/src/domzgr.f90

# Apply the WEIGHTS patches once to fresh sources.
# Comment out the patch commands when recompiling patched sources.
cd $NEMO/tools/WEIGHTS/src
patch -b < $gituhb_download/CS1.5_NEMO_support/tool_patch_files/scripinterp_mod.patch
patch -b < $gituhb_download/CS1.5_NEMO_support/tool_patch_files/scripinterp.patch
patch -b < $gituhb_download/CS1.5_NEMO_support/tool_patch_files/scrip.patch
patch -b < $gituhb_download/CS1.5_NEMO_support/tool_patch_files/scripshape.patch
patch -b < $gituhb_download/CS1.5_NEMO_support/tool_patch_files/scripgrid.patch

# Use standard Fortran command-line routines for the GNU compiler.
cd $NEMO/tools
patch -b < $gituhb_download/CS1.5_NEMO_support/tool_patch_files/command_arguments.patch

# And finally compile the NEMO tools.
cd $NEMO/tools
./maketools -m $HPC_TARG -n NESTING
ls $TDIR/NESTING/BLD/bin/*.exe
./maketools -m $HPC_TARG -n REBUILD_NEMO
ls $TDIR/REBUILD_NEMO/BLD/bin/rebuild_nemo.exe
./maketools -m $HPC_TARG -n WEIGHTS
ls $TDIR/WEIGHTS/BLD/bin/scrip.exe
ls $TDIR/WEIGHTS/BLD/bin/scripgrid.exe
ls $TDIR/WEIGHTS/BLD/bin/scripinterp.exe
ls $TDIR/WEIGHTS/BLD/bin/scripshape.exe
./maketools -m $HPC_TARG -n DOMAINcfg
ls $TDIR/DOMAINcfg/BLD/bin/make_domain_cfg.exe

cd $gituhb_download/Scripts

###################################################################
#                       FINISHED
###################################################################
