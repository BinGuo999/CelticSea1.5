#!/bin/bash
#SBATCH --job-name=CS15_test_1993
#SBATCH --time=24:00:00
#SBATCH --nodes=4
#SBATCH --exclusive
#SBATCH --hint=nomultithread
#SBATCH --distribution=block:cyclic
#SBATCH --ntasks-per-core=1
#SBATCH --cpus-per-task=1
#SBATCH --account=n01-class
#SBATCH --partition=standard
#SBATCH --qos=standard

set -eo pipefail
shopt -s nullglob
cd "${SLURM_SUBMIT_DIR:?Submit this script from the model run directory}"

# Cirrus environment: 8 XIOS ranks + 812 NEMO ranks on four nodes.
module load PrgEnv-gnu/8.6.0
module load craype-network-ofi cray-mpich/8.1.32
module load cray-hdf5-parallel/1.14.3.5 cray-netcdf-hdf5parallel/4.9.0.17
module load libfabric xpmem
export OMP_NUM_THREADS=1 FI_CXI_OPTIMIZED_MRS=false
unset FI_MR_CACHE_MONITOR     # Keep the successfully tested baseline environment.
ulimit -s unlimited
ulimit -c 0

# Single Slurm step: keep the existing 8 / 271 / 271 / 270 rank placement.
scontrol show hostnames "$SLURM_JOB_NODELIST" | awk '
    NR == 1 { n=8 }
    NR == 2 || NR == 3 { n=271 }
    NR == 4 { n=270 }
    { for (i=0; i<n; i++) print }
' > rank_hosts.txt
export SLURM_HOSTFILE="$PWD/rank_hosts.txt"
printf '0-7 ./xios_server.exe\n8-819 ./nemo.exe\n' > programs.conf
srun_command="srun --propagate=CORE,STACK --ntasks=820 \
--hint=nomultithread --distribution=arbitrary --ntasks-per-core=1 --cpus-per-task=1 \
--cpu-bind=verbose --mem-bind=none --multi-prog programs.conf"

# One-year test: January through December 1993, starting from the IC.
# Each month writes a restart used by the following month.
iy1=1993
iy2=1993
ms=1
end_month=12
nit0=1
tpd=1080                    # Timesteps per day: 86400 / 80 = 1080
date0=19930101
expname="CS1.5"
OUTPUTDIR="$PWD/OUTPUT"
mkdir -p RESTART

for ((year=iy1; year<=iy2; year++)); do
    first_month=1
    last_month=12
    if [ "$year" -eq "$iy1" ]; then first_month=$ms; fi
    if [ "$year" -eq "$iy2" ]; then last_month=$end_month; fi

    for ((mm=first_month; mm<=last_month; mm++)); do
        # Stop before starting another month once 19 hours have elapsed.
        if (( SECONDS >= 19 * 3600 )); then
            echo "Time to resubmit: iy1=$year iy2=$iy2 ms=$mm nit0=$nit0"
            exit 0
        fi
        month=$(printf '%02d' "$mm")
        OUTDIR="$OUTPUTDIR/$year/$month"
        [ ! -e "$OUTDIR" ] || { echo "Output directory already exists: $OUTDIR" >&2; exit 1; }

        # Calculate the month's length, including leap years.
        case "$mm" in
            4|6|9|11) days=30 ;;
            2)
                days=28
                if (( year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) )); then days=29; fi ;;
            *) days=31 ;;
        esac
        nitend=$((nit0 + days * tpd - 1))

        # First month: IC. Later months: previous restart in RESTART/.
        if [ "$nit0" -eq 1 ]; then
            rstart=.false.
            inits=.true.
            rstctl=0
            rstfile=""
        else
            rstart=.true.
            inits=.false.
            rstctl=2
            rstfile="${expname}_$(printf '%08d' "$((nit0 - 1))")_restart"
            [ -s "RESTART/$rstfile.nc" ] || { echo "Missing restart: $rstfile.nc" >&2; exit 1; }
        fi

        # Prepare the namelist and run this month in the main directory.
        sed -e "s,__IT000__,$nit0,g" \
            -e "s,__ITEND__,$nitend,g" \
            -e "s,__DATE0__,$date0,g" \
            -e "s,__RSTART__,$rstart,g" \
            -e "s,__INITS__,$inits,g" \
            -e "s,__RSTFILE__,$rstfile,g" \
            -e "s,__RSTCTL__,$rstctl,g" \
            -e 's,__RSTINDIR__,./RESTART,g' \
            -e 's,__RSTOUTDIR__,./RESTART,g' \
            namelist.template > namelist_cfg
        echo "Running $year/$month: timesteps $nit0-$nitend"
        eval "$srun_command"

        # Move output files, following eAMM7's run313.slurm.
        date
        mkdir -p "$OUTDIR"
        mv ocean.output namelist_cfg output.namelist.dyn run.stat run.stat.nc "$OUTDIR/"
        mv "${expname}"_*.nc "$OUTDIR/"
        if [ -f timing.output ]; then mv timing.output "$OUTDIR/"; fi

        current_stp=$(sed -n '1p' time.step)
        if [ "$current_stp" -ne "$nitend" ]; then
            echo "Incomplete month: $year/$month" >&2
            exit 1
        fi

        # Keep a copy of this month's restart with its results.
        restart="${expname}_$(printf '%08d' "$nitend")_restart.nc"
        mkdir -p "$OUTDIR/RESTARTS"
        cp -p "RESTART/$restart" "$OUTDIR/RESTARTS/"
        mv time.step "$OUTDIR/"
        nit0=$((nitend + 1))
    done
done

echo "Finished through $iy2/$month. Results: $OUTPUTDIR"
