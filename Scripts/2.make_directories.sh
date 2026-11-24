#!/bin/bash

#:'
#
#***********************
#make_directories.sh
#***********************
#
# Step 2. Create the build directories before compiling XIOS. Run from Scripts/.
set -e
source ./1.make_path.sh

mkdir -p "$WDIR"
mkdir -p "$RUND"
mkdir -p "$WDIR/BUILD_EXE"
mkdir -p "$WDIR/BUILD_EXE/NEMO"
mkdir -p "$WDIR/BUILD_EXE/NEMO/$NEMO_VER"
mkdir -p "$WDIR/BUILD_CFG"
mkdir -p "$WDIR/BUILD_EXE/XIOS"
mkdir -p "$XIOS_DIR"
mkdir -p "$WDIR/BUILD_CFG/SURFACE_FORCING"
mkdir -p "$WDIR/BUILD_CFG/DOMAIN"
mkdir -p "$WDIR/BUILD_CFG/INITIAL_CONDITION"
mkdir -p "$WDIR/BUILD_CFG/OPEN_BOUNDARIES"
mkdir -p "$WDIR/BUILD_CFG/RIVERS"
mkdir -p "$EXP"

############### Check directories ################
echo
echo "Checking created directories..."

missing=0

for directory in \
    "$WDIR" \
    "$WDIR/BUILD_CFG/RIVERS" \
    "$WDIR/BUILD_EXE" \
    "$WDIR/BUILD_EXE/NEMO" \
    "$WDIR/BUILD_EXE/NEMO/$NEMO_VER" \
    "$WDIR/BUILD_CFG" \
    "$WDIR/BUILD_EXE/XIOS" \
    "$XIOS_DIR" \
    "$WDIR/BUILD_CFG/SURFACE_FORCING" \
    "$WDIR/BUILD_CFG/DOMAIN" \
    "$WDIR/BUILD_CFG/INITIAL_CONDITION" \
    "$WDIR/BUILD_CFG/OPEN_BOUNDARIES" \
    "$RUND" \
    "$EXP"
do
    if [ -d "$directory" ]; then
        echo "[OK]      $directory"
    else
        echo "[MISSING] $directory"
        missing=$((missing + 1))
    fi
done

echo
if [ "$missing" -eq 0 ]; then
    echo "All directories exist."
else
    echo "$missing directories are missing."
fi
