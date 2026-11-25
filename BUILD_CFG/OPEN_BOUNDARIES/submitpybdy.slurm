#!/bin/bash
#SBATCH --job-name=pybdy
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=3
#SBATCH --account=n01-FOCUS
#SBATCH --mem=64GB
#SBATCH --partition=serial
#SBATCH --qos=serial

source ~/.bashrc
conda activate pybdy

export JAVA_HOME=/usr/lib64/jvm/java-11-openjdk-11
export JVM_PATH=$JAVA_HOME/lib/server/libjvm.so

cd "$SLURM_SUBMIT_DIR" || exit 1
pybdy -s "${1:?Pass a pyBDY namelist filename to sbatch}"
