#!/bin/bash
#SBATCH --job-name=mborrus_MiMA
#SBATCH --nodes=8
#SBATCH --tasks-per-node=16
#SBATCH --time=1-00:00:00
#SBATCH --mem=16GB
#SBATCH --constraint=[CLASS:SH3_CBASE|CLASS:SH3_CPERF]
#SBATCH --partition=serc
#SBATCH -o ./jobfiles/mima_test%j.out
#SBATCH -e ./jobfiles/mima_test%j.err

# Load modules
module purge
module unuse /usr/local/modulefiles
  #Link to the Spack Environment
module use /scratch/users/myoder96/spack_dev/zen2/spack/share/spack/lmod_zen2/linux-centos7-x86_64/Core
  #Load Intel
module --ignore-cache load intel-yoda/
  #Load NetCDF
ml load netcdf/4.4.1.1
  #Load MPICH
module load mpich-yoda
  #Load the C and Fortran versions of NetCDF
module load netcdf-c-yoda netcdf-fortran-yoda

#overkill to make sure everything is seen...
export "PYTHONPATH=$PYTHONPATH:/home/mborrus/"
export "PYTHONPATH=$PYTHONPATH:/scratch/users/mborrus/MiMA/code/MiMAv0.1_mborrus/src/atmos_param/dd_drag/"
export "PYTHONPATH=$PYTHONPATH:/scratch/users/mborrus/MiMA/code/MiMAv0.1_mborrus/src/atmos_param/"
export "PYTHONPATH=$PYTHONPATH:/home/users/mborrus/.pyenv/versions/3.6-dev/lib/python3.6/site-packages/"
export "PYTHONPATH=$PYTHONPATH:/scratch/users/mborrus/MiMA/code/MiMAv0.1_mborrus/wavenet/"
export "PYTHONPATH=$PYTHONPATH:/scratch/users/mborrus/MiMA/code/MiMAv0.1_mborrus/wavenet/models/"
export "HDF5_DISABLE_VERSION_CHECK=1"

# setup run directory
run=mima_test
N_PROCS=8

base=/scratch/users/mborrus/MiMA
user=mborrus
executable=${base}/code/MiMAv0.1_mborrus/exp/exec.Sherlock/mima.x
input=${base}/code/MiMAv0.1_mborrus/input
rundir=${base}/runs/$run

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

CCOMB=${base}/code/MiMAv0.1_mborrus/bin/mppnccombine.Sherlock
$CCOMB -r atmos_daily.nc atmos_daily.nc.*
$CCOMB -r atmos_avg.nc atmos_avg.nc.*
