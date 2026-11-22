#!/bin/bash
# Prepare the 1993 test run. Run from the Scripts directory.
set -e
source ./1.make_path.sh

#------------------------------------------------------------------
# 1. Copy the run template
#------------------------------------------------------------------
mkdir -p $EXP
cp $gituhb_download/RUN_DIRECTORIES/EXP_test_1993/* $EXP/
cd $EXP


#------------------------------------------------------------------
# 2. Link only the 1993 forcing files
#------------------------------------------------------------------

mkdir -p IC OBC SBC river TIDES RESTART

ln -s $FORCING_DIR/IC/*y1993*.nc IC/
ln -s $FORCING_DIR/OBC/*y1993m*.nc OBC/
ln -s $FORCING_DIR/SBC/Forcing/*y1993.nc SBC/
ln -s $FORCING_DIR/River/*y1993.nc river/
ln -s $FORCING_DIR/TIDES/*.nc TIDES/

# Domain, boundary coordinates and atmospheric interpolation weights.
ln -s $FORCING_DIR/domain_cfg.nc domain_cfg.nc
ln -s $FORCING_DIR/OBC/coordinates.bdy.nc OBC/coordinates.bdy.nc
ln -s OBC/coordinates.bdy.nc coordinates.bdy.nc
# NEMO reads the weights relative to the atmospheric cn_dir (./SBC/).
ln -s $FORCING_DIR/SBC/Forcing/weights_era5_CELTIC_bilin.nc SBC/weights_era5_CELTIC_bilin.nc
ln -s $FORCING_DIR/SBC/Forcing/weights_era5_CELTIC_bicubic.nc SBC/weights_era5_CELTIC_bicubic.nc

#------------------------------------------------------------------
# 3. Link the compiled executables
#------------------------------------------------------------------

ln -s $CONFIG_DIR/BLD/bin/nemo.exe nemo.exe
ln -s $XIOS_DIR/bin/xios_server.exe xios_server.exe

# The Slurm script runs 12 months from rest with an 80-second timestep.
# 365 days * 86400 seconds / 80 = 394200 timesteps for the full year.
echo "1993 test run prepared in: $EXP"
echo "Review the account and resources in $EXP/runnemo.slurm before submission."
echo "To submit: cd $EXP"
echo "           sbatch runnemo.slurm"
