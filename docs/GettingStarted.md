[back to top](https://mjucker.github.io/MiMA)

# Getting started with MiMA

This model is based on the gray radiation model of [Frierson, Held, and Zurita-Gotor, JAS (2006)](http://journals.ametsoc.org/doi/abs/10.1175/JAS3753.1).
In fact, it even includes that exact model with a namelist switch flag. The major development step of MiMA is the replacement of the gray radiation scheme with a full radiative transfer code. For maximum portability and generality, that radiative transfer code is the Rapid Radiative Transfer Model [RRTM](http://rtweb.aer.com/rrtm_frame.html), developed by AER, and described in the references below.

## Downloading source
You can download MiMA for free. However, we ask that you cite all relevant references given on the [front page](https://mjucker.github.com/MiMA/) with any publications that might result from its use.

Get the latest version from [GitHub](https://github.com/mjucker/MiMA/releases/latest).

## Compiling

### Dependencies
  * The code in its present form will only compile with Intel `ifort` and `icc` compilers. This description will assume `ifort` and `icc` are available.
  * MiMA reads and writes to `netCDF`, so `netCDF` needs to be installed on the system.
  * Being parallel, `MPI` needs to be there too.
  * The build system now uses [CMake](https://cmake.org/).
  * MiMA currently depends on Python for wavenet.

CMake should be able to find Python, MPI and NetCDF on your system,
particularly if your administrator has installed them with CMake in mind.

To build, do something like this from the MiMA top-level directory:
```
mkdir build # where the code will be build.  You may call it whatever you like, and have many such directories.
cd build
cmake -DCMAKE_BUILD_TYPE:STRING=Debug .. # or -DCMAKE_BUILD_TYPE:STRING=Release for the optimised build
```

CMake will search for MiMA's dependencies.  If it can't find your NetCDF
library you may set the environment variable `NETCDF_DIR` to the directory
containing its `bin`, `lib`, and `include` directories and re-run the `cmake`
command.  If it is struggling to find the `ifort` compiler or the MPI libraries
make sure you've done whatever is needed to get `ifort` and `mpif90` into your
path (e.g. `module load intel` or `module load impi`).

Once CMake has finished with `-- Configuring done; -- Generating done` you are
ready to run `make`.  If you usually run `make` in a batch job then all your
script needs to do is `cd` to the build directory you created above and run
`make` or `make -j N` where N is the number of processors you want to use to
build MiMA.  If you are building directly the procedure is the same: `cd`
to the build directory and run `make` or `make -j N`.


### Developing MiMA 
If you are developing MiMA then once you have made your changes you only
need to run `make` (or `make -j N`) in the build directory.  CMake will
build only what has changed.

To add files, place them in the relevant directory and add the source file
in the appropriate `CMakeLists.txt` file.  E.g. if you have added a file in
`src/atmos_spectral/driver/solo/` then you'd add it to the `CMakeLists.txt`
file in `src/atmos_spectral/`.  Running `make` in the build directory
should pick up this change but if it doesn't you can repeat your
`cmake ..` invocation.

If the build becomes hopelessly confused you can always entirely delete the
build directory and re-create it as above.


## Test run

A small test run is defined in the input/ directory.
* `input.nml`: This is the most important file, where all the input parameters within the various namelists of MiMA can be set. If a variable is not present in `input.nml`, it will be set to the (hard coded) default value. This file completely defines the simulation you are running.
* `diag_table`: A list of diagnostic outputs you would like to have in your output files. This does not change the simulation you are running, but simply lets you decide which variables you'd like to have in the output, how frequently you'd like the output, and whether the output should be averaged or instantaneous.
* `field_table`: A list of passive tracers you'd like to advect during the simulation. There are two types: grid or spectral tracers. To get the temporal evolution of the tracers (or the time average), add the name of the tracer as diagnostic output to diag_table.

MiMA will automatically look for `input.nml`, so it is run without any explicit input (i.e. ``./mima.x`` is fine - don't try ``./mima.x < input.nml``).

The test run will be one 360-day year with the following parameters:
* no surface topography
* ozone from the file `INPUT/ozone_1990.nc` (which is also in the input/ directory)
* 300ppm CO2
* solar constant of 1360W/m2
* circular Earth-Sun orbit with 1UA radius
* NH solstice on December 30 (day 360)
* mixed layer ocean depth of 100m
* constant surface albedo of 0.27
* meridional Q flux of 30W/m2
* sponge layer Rayleigh friction above 50Pa
* Betts-Miller convection and large scale condensation
* RRTM radiation scheme

To run the test simulation, do the following:
```
EXECDIR=/PATH/TO/RUN/DIRECTORY
cp -r input/* $EXECDIR/
cp exp/exec.$PLATFORM/mima.x $EXECDIR/
cd $EXECDIR
mkdir RESTART
mpiexec -n $N_PROCS ./mima.x
CCOMB=/PATH/TO/MiMA/REPOSITORY/bin/mppnccombine.$PLATFORM
$CCOMB -r atmos_daily.nc atmos_daily.nc.*
$CCOMB -r atmos_avg.nc atmos_avg.nc.*
```
The last three lines make sure the indiviudal diagnostics files from each CPU are combined into one daily and one average file.

## Radiation options

By default, MiMA uses the RRTM radiation code. This is set by `do_rrtm_radiation = .true.` (default). There are, however, two more options for radiation, described below.

MiMA includes the gray radiation scheme developed by Dargan Frierson ([Frierson, Held, Zurita-Gotor, JAS (2006)](http://journals.ametsoc.org/doi/abs/10.1175/JAS3753.1) ). To switch between the radiation schemes, the flags `do_grey_radiation`, and `do_rrtm_radiation` in the namelist `physics_driver_nml` can be set accordingly (only one of them should be `.true.` of course). 

Theoretically, there is also the possibility of running the full AM2 radiation scheme, with the flag `do_radiation in physics_driver_nml`. However, this option will need a lot of input files for tracer concentration, which are not part of the MiMA repository. This option, although all the relevant files are present and being compiled, has never been tested, and should only be used with great caution.
