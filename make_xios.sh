#!/bin/bash
# Script to set up CS1.5 on Cirrus
# Adapted from eAMM7 from setup_AMM15_CO9_P2_archer from  se-eORCA025_setup
 
display_usage() { 
   echo
   echo "  Auto-Config: Celtic Sea on Cirrus"
   echo "  ***************************************"
   echo
   echo "  usage: ${0##*/} -w path_to_install_nemo -s path_to_repo"
   echo
   echo "  flags:  -w full path to where nemo/xios will be installed"
   echo "          -s full path to where AMM repository resides"
   echo
   exit 1
	} 
# if less than three arguments supplied, display usage 
	if [  $# -le 3 ]
	then 
		display_usage
		exit 1
	fi 
# if less than two arguments supplied, display usage 
	if [  $# -ge 5 ] 
	then 
		display_usage
		exit 1
	fi 
# check whether user had supplied -h or --help . If yes display usage 
	if [[ ( $# == "--help") ||  $# == "-h" ]] 
	then 
		display_usage
		exit 0
	fi 

while getopts w:x:s: option
  do
  case "${option}"
  in
  w) export WORK=${OPTARG};;
  s) export REPO_DIR=${OPTARG};;
  esac
done

#################################################################################################
# set paths
#################################################################################################
export CONFIG=CS1.5_NEMO
export WORK_DIR=$WORK/$CONFIG
export XIOS_DIR=$WORK/$CONFIG
export HPC_TARG=cirrus-gnu-mpich
#################################################################################################

echo $WORK_DIR

if [ ${WORK_DIR:0:1} != "/" ]; then
  echo "WORK_DIR must use full path"
  exit 1
fi

if [ ${XIOS_DIR:0:1} != "/" ]; then
  echo "XIOS_DIR must use full path"
  exit 1
fi

if [ ${REPO_DIR:0:1} != "/" ]; then
  echo "REPO_DIR must use full path"
  exit 1
fi

# Change to some working directory of choice
if [ ! -d "$WORK_DIR" ]; then
  mkdir -p $WORK_DIR
fi
cd $WORK_DIR


echo "Making sure that the correct modules are loaded"

case "${HPC_TARG}"
  in
  cirrus-gnu-mpich) . $REPO_DIR/CS1.5_NEMO_support/co9_modules_gnu-mpich
           ;;
  *)       echo "Machine not recognised"
           echo "Machines available: cirrus-gnu-mpich"
           exit 1
esac

export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

# Currently running 4.0.4 for AMM7 and revision 13653
NEMO_VER=4.0.4
REV=13653

#################################################################################################
# Checkout the NEMO code from the SVN Paris repository 
#################################################################################################
echo "Checking out NEMO repository"
###################################################################################
# have to co everything to get ext files from svn-mirror.nemo-ocean.eu
####################################################################################
svn co -r$REV https://svn-mirror.nemo-ocean.eu/NEMO/releases/r4.0/r$NEMO_VER nemo
####################################################################################
# remove extra "stuff" to tidy up
####################################################################################
rm -rf nemo/ext/AGRIF
rm -rf nemo/doc
rm -rf nemo/tests

##svn co -r$REV http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$NEMO_VER --depth empty nemo
##svn co -r$REV http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$NEMO_VER/src --depth infinity nemo/src
##svn co -r$REV http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$NEMO_VER/cfgs/SHARED nemo/cfgs/SHARED
##svn export http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$NEMO_VER/cfgs/ref_cfgs.txt nemo/cfgs/ref_cfgs.txt

cd nemo

# Now check EXTERNALS revision number before checking out the rest
#for ext_name in mk FCM IOIPSL   
#  do   
#  ext=`svn propget svn:externals | grep $ext_name | cut -c2-`   
#  svn co http://forge.ipsl.jussieu.fr/nemo/svn/$ext
#done
#
#ext=`svn propget svn:externals | grep makenemo | cut -c2-`
#svn export http://forge.ipsl.jussieu.fr/nemo/svn/$ext
#################################################################################################

mkdir arch

# Setup the directory structure
mkdir $WORK_DIR/nemo/cfgs/cs1.5

#################################################################################################
#   XIOS installation
#################################################################################################
# Build a private GNU installation; the shared tree is read only input.
export XIOS_DIR="$WORK_DIR/xios3-gnu"
(
  set -e
  XIOS_SOURCE=/epccfs/n01/shared/xios3
  if [ "${PE_ENV:-}" != GNU ]; then
    echo "XIOS requires PrgEnv-gnu, matching the NEMO compiler." >&2
    exit 1
  fi
  : "${NETCDF_DIR:?Load the GNU parallel NetCDF module first}"
  : "${HDF5_DIR:?Load the GNU parallel HDF5 module first}"
  test -x "$XIOS_SOURCE/make_xios"

  # Refuse an existing destination, including symlinks, to avoid changing
  # another installation or mixing old Cray outputs with the GNU build.
  mkdir "$XIOS_DIR" || {
    echo "XIOS destination must be new: $XIOS_DIR" >&2
    exit 1
  }
  # Dereference source symlinks so no copied link can write back to the
  # shared installation. Omit generated compiler-specific build outputs.
  rsync -rL \
    --exclude='/.git/' --exclude='/bin/' --exclude='/lib/' \
    --exclude='/inc/' --exclude='/obj/' --exclude='/ppsrc/' \
    --exclude='/done/' --exclude='/flags/' --exclude='/.cache/' \
    --exclude='/Makefile' --exclude='/arch.env' \
    --exclude='/arch.fcm' --exclude='/arch.path' \
    --exclude='/bld_dir.cfg' --exclude='/config.fcm' \
    "$XIOS_SOURCE/" "$XIOS_DIR/"
  cd "$XIOS_DIR"

  # Start from the supplied GNU template; Cray wrappers select GNU under
  # PrgEnv-gnu. Let ftn supply MPI libraries for the current Cirrus stack.
  cp arch/arch-X86_ARCHER2-Gnu.fcm arch/arch-X86_CIRRUS-Gnu.fcm
  cp arch/arch-X86_ARCHER2-Gnu.path arch/arch-X86_CIRRUS-Gnu.path
  printf '%s\n' '# Use the GNU modules already loaded by the setup script.' \
    > arch/arch-X86_CIRRUS-Gnu.env
  sed -i 's/ -lmpichf90//g' arch/arch-X86_CIRRUS-Gnu.fcm

  echo "Compiling private GNU XIOS3 in $XIOS_DIR"
  ./make_xios --full --prod --arch X86_CIRRUS-Gnu \
    --netcdf_lib netcdf4_par --job 16
  test -s lib/libxios.a
  test -x bin/xios_server.exe
) || {
  echo "Private XIOS build failed; stopping before NEMO compilation." >&2
  exit 1
}

#################################################################################################

cd $WORK_DIR/nemo
cp $REPO_DIR/CS1.5_NEMO_support/NEMO_arch/* ./arch
# Dirty fix to hard wire path otherwise user will have to set XIOS_DIR in every new shell session
sed -i "s?XXX_XIOS_DIR_XXX?$XIOS_DIR?" ./arch/arch-${HPC_TARG}.fcm

echo 'cs1.5 OCE' >> $WORK_DIR/nemo/cfgs/work_cfgs.txt

echo "Gathering forcing data"

export CONFIG_DIR=$WORK_DIR/nemo/cfgs/cs1.5
echo $CONFIG_DIR

cd $CONFIG_DIR

mkdir -p $CONFIG_DIR/EXPREF
cd $CONFIG_DIR/EXPREF

cp $XIOS_DIR/bin/xios_server.exe $CONFIG_DIR/EXPREF/xios_server.exe

cd $WORK_DIR/nemo
 
#################################################################################################
# Compile NEMO:
# First copy eAMM7 mods
#################################################################################################
mkdir -p $CONFIG_DIR/MY_SRC
cp "$REPO_DIR"/MY_SRC/* "$CONFIG_DIR/MY_SRC/"
cp $REPO_DIR/CS1.5_NEMO_support/cpp_co9-amm7.fcm $CONFIG_DIR/cpp_cs1.5.fcm

echo "Compiling nemo eAMM7 Config"
./makenemo -m ${HPC_TARG} -r cs1.5 -j 16
#################################################################################################

cp $CONFIG_DIR/BLD/bin/nemo.exe  $CONFIG_DIR/EXPREF/nemo.exe
cp $REPO_DIR/CS1.5_NEMO_support/*xml $CONFIG_DIR/EXPREF/.
cp $REPO_DIR/CS1.5_NEMO_support/namelist_ref $CONFIG_DIR/EXPREF/.
cp $REPO_DIR/CS1.5_NEMO_support/namelist_cfg_eAMM7 $CONFIG_DIR/EXPREF/namelist_cfg

echo
echo "  Auto-Config: eAMM7"
echo "  *****************************"
echo
echo "  To run the eAMM7 Configuration:"
echo
echo "  - cp -rP EXPREF EXP_MYRUN "
echo "  - link the correct domain_cfg.nc "
echo "  - update the runscript accordingly "
echo "      (project code, nodes, modules, etc)"
echo

echo "  - submit via the sbatch command"

echo    
