module prescribed_heating_mod

! kd: stratospheric waming experiments, as done in hs by epg
! note gaussian in log p, not p
! total heating = sum_1^n amplitude exp[ -(lat-ypos)^2/y_wid^2] -
! (z-zpos)^2/zwid^2 ] where n is the number of heatings in the
! namelist and z=-href*log(p/p0).

use     fms_mod, only: file_exist, open_namelist_file, &
        check_nml_error, close_file
     implicit none

        
         ! read namelist, allocate variables, set up diagnostics, ...
        real :: P00 = 1.e5
        real :: glzh_href = 7.5               ! we assume log pressure height
        integer, parameter :: max_gaussian_lat_z_heatings = 10
        ! if you want more than one Gaussian, make these vectors in the
        ! namelist, as when you specify multiple Gaussian mountains.
        !  All should be of the same length!
        real, dimension(max_gaussian_lat_z_heatings) :: glzh_amplitude = 0.
        ! heating amplitude (K/day)
        real, dimension(max_gaussian_lat_z_heatings) :: glzh_ypos = 0.       ! peak heating latitude
        real, dimension(max_gaussian_lat_z_heatings) :: glzh_ywid = 0.       ! half width in lat (degrees)
        real, dimension(max_gaussian_lat_z_heatings) :: glzh_zpos = 0.       ! peak heating height
        real, dimension(max_gaussian_lat_z_heatings) :: glzh_zwid = 0.       ! half width in z (Km)
        real :: deg_to_rad = 3.14159265358979/180.0
 
        namelist /prescribed_heating_nml/ glzh_href, &
                 glzh_amplitude, glzh_ypos, glzh_ywid, &
                 glzh_zpos, glzh_zwid

     contains
       
       subroutine prescribed_heating_init

         ! read namelist
         integer unit, io, ierr
            if (file_exist('input.nml')) then
               unit = open_namelist_file ( )
               ierr=1; do while (ierr /= 0)
               read  (unit, nml=prescribed_heating_nml, iostat=io, end=10)
               ierr = check_nml_error (io, 'prescribed_heating_nml')
            enddo
               10     call close_file (unit)
            endif

         ! convert degrees to radians
         glzh_ypos = glzh_ypos * deg_to_rad
         glzh_ywid = glzh_ywid * deg_to_rad
         ! convert K/day to K/second
         glzh_amplitude = glzh_amplitude/86400

       end subroutine prescribed_heating_init


!##################################################################
       
       subroutine prescribed_heating (p_full, tdt, lat)

        ! step through the vector of Gaussian heatings, which allows
         ! you to specify up to
         ! "max_gaussian_lat_z_heatings" different heatings 
         real, intent(in),    dimension(:,:)     :: lat
         real, intent(in),    dimension(:,:,:)   :: p_full
         real, intent(inout), dimension(:,:,:)   :: tdt
         integer :: i,j,k,n
         do n = 1, max_gaussian_lat_z_heatings

            ! most often you only need a few heatings, so these vectors
            ! are full of zeros.
            ! this statement speeds you past these void entries
            if ( glzh_amplitude(n) == 0. ) cycle

            do k=1,size(tdt,3)
               do j=1,size(tdt,2)
                  do i=1,size(tdt,1)

                     tdt(i,j,k) = tdt(i,j,k) + glzh_amplitude(n) * &
                          exp( -((lat(i,j)-glzh_ypos(n))/glzh_ywid(n))**2.   &
                               -((-glzh_href*log(p_full(i,j,k)/P00)-glzh_zpos(n)) &
                                 /glzh_zwid(n))**2.)
                  enddo
               enddo
            enddo

         enddo
              
    end subroutine prescribed_heating



!##################################################################
! might be useful:
!       subroutine prescribed_heating_end
!       end subroutine prescribed_heating_end

  end module prescribed_heating_mod
