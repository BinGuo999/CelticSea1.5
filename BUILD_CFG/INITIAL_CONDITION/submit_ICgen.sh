#!/bin/bash 

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1 
#SBATCH --account=nemo

#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH -o %j.out 
#SBATCH -e %j.err
#SBATCH --time=10:00:00
#SBATCH --mem=50G

# executable 
#python -u calc_mld.py
source ~/.bashrc
conda activate coast

cd /home/users/binguo/IC/CelticS1.5_ICgen
python -u CelticS1.5_ICgen.py
