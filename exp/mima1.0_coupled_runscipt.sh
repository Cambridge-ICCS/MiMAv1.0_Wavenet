#!/bin/bash
#SBATCH --job-name=mima_kcode
#SBATCH --nodes=2
#SBATCH --tasks-per-node=16
#SBATCH --time=10-00:00:00
#SBATCH --mem=8GB
#SBATCH --partition=cees
#SBATCH -o mima_kcode.out
#SBATCH -e mima_kcode.err

# Load modules
module purge
module unuse /usr/local/modulefiles

module load intel/19 #.1.0.166
module load openmpi_3/ #3.1.4

module load netcdf/4.7.1
module load netcdf-fortran/4.5.2

export "PYTHONPATH=/home/mborrus/:/scratch/mborrus/models/MiMAv0.1_mborrus/src/atmos_param"
export "HDF5_DISABLE_VERSION_CHECK=1"

# setup run directory
user=mborrus
run=mima_kcode
executable=/scratch/${user}/code/MiMAv0.1_mborrus/exp/exec.SE3Mazama/mima.x
input=/scratch/${user}/code/MiMAv0.1_mborrus/input
rundir=/scratch/${user}/runs/$run
#rundir=/data/cees/${user}/ssw_data/$run
N_PROCS=2

# Make run dir
[ ! -d $rundir ] && mkdir $rundir
# Copy executable to rundir
cp $executable $rundir/
# Copy input to rundir
cp -r $input/* $rundir/
# Run the model
cd $rundir

ulimit -s unlimited

[ ! -d RESTART ] && mkdir RESTART
#mpiexec -n $N_PROCS mima.x
mpiexec -n $N_PROCS mima.x

CCOMB=/scratch/${user}/models/code/MiMAv0.1_mborrus/bin/mppnccombine.SE3Mazama
$CCOMB -r atmos_daily.nc atmos_daily.nc.*
$CCOMB -r atmos_avg.nc atmos_avg.nc.*


