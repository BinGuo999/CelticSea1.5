#!/bin/bash
#
#***********************
#make_paths.sh
#***********************

# Step 1. Configure the paths before creating directories or compiling XIOS.
# 
# 
############  things to be changed  ##############################
# Path to your downloaded or cloned CelticSea1.5 repository.
# Change this path if you download the repository somewhere else.
export gituhb_download=/epccfs/n01/n01/binguo/github_binguo999/CelticSea1.5-main

export WDIR=/epccfs/n01/n01/binguo/CS1.5_test
# Set the configuration name that describes the NEMO executable
export CONFIG=CelticSea1.5 # NEMO exec that based on AMM15 configuration
# Set the NEMO version
export NEMO_VER=NEMO_4.0.4
# The following can then be automatically defined
# Set some HPC parameters to control compilation
export HPC_TARG=cirrus-gnu-mpich
# Directory containing the domain and forcing files.
export FORCING_DIR=/epccfs/n01/n01/binguo/github_binguo999/CelticSea1.5_forcing_1993-95
############  things to be changed  ##############################

############  things no need to change  ##############################
# Define parent paths before the paths that use them.
export XIOS_DIR=$WDIR/BUILD_EXE/XIOS/xios-3 # base XIOS source and build path
export NEMO=$WDIR/BUILD_EXE/NEMO/$NEMO_VER # base NEMO source and build path
export CDIR=$NEMO/cfgs
export TDIR=$NEMO/tools # base tools source and build directory
export RUND=$WDIR/RUN_DIRECTORY
export EXP=$RUND/CS1.5_1993_TEST
export CONFIG_DIR=$CDIR/$CONFIG
#export SBC=$WDIR/BUILD_CFG/SURFACE_FORCING
export DOMAIN=$WDIR/BUILD_CFG/DOMAIN # base directory for building domain configuration file

############### Show settings ################
echo "gituhb_download   = $gituhb_download"
echo "FORCING_DIR = $FORCING_DIR"
echo "CONFIG     = $CONFIG"
echo "CONFIG_DIR = $CONFIG_DIR"
echo "WDIR       = $WDIR"
echo "NEMO_VER   = $NEMO_VER"
echo "NEMO       = $NEMO"
echo "XIOS_DIR   = $XIOS_DIR"
echo "CDIR       = $CDIR"
echo "TDIR       = $TDIR"
echo "DOMAIN     = $DOMAIN"
echo "HPC_TARG   = $HPC_TARG"
echo "RUND       = $RUND"
echo "EXP        = $EXP"
