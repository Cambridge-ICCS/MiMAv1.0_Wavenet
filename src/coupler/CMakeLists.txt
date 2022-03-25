
set ( COUPLER_SOURCES 
coupler_main.f90
simple_surface.f90
surface_flux.f90
)

# NB this is where the executable is defined.
target_sources ( mima.x PRIVATE ${COUPLER_SOURCES} )
