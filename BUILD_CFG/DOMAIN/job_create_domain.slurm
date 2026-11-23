#!/bin/bash
#SBATCH --job-name=nemo_dom
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --account=n01-class
#SBATCH --partition=standard
#SBATCH --qos=short

set -e

module load PrgEnv-gnu/8.6.0
module load craype-network-ofi cray-mpich/8.1.32
module load cray-hdf5-parallel/1.14.3.5 cray-netcdf-hdf5parallel/4.9.0.17
module load libfabric xpmem

export OMP_NUM_THREADS=1

srun --ntasks=1 ./make_domain_cfg.exe
