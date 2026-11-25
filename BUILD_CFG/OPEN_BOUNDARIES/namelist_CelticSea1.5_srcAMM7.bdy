!!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
!! NEMO/OPA  : namelist for BDY generation tool
!!
!! AMM7 daily forcing for the CELTIC8 GEG SF12 grid.
!!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

!------------------------------------------------------------------------------
!  vertical coordinate
!------------------------------------------------------------------------------
   sn_src_zgr_type = 'sco'                                   ! AMM7 source vertical coordinate
   sn_dst_zgr_type = 'sco'                                   ! Celtic Sea target vertical coordinate

!------------------------------------------------------------------------------
!  grid information
!------------------------------------------------------------------------------
   sn_src_hgr = './AMM7_domain_cfg.nc'                   ! AMM7 horizontal grid
   sn_src_zgr = './AMM7_domain_cfg.nc'                   ! AMM7 vertical grid
   sn_dst_hgr = './domain_cfg.nc'                            ! Celtic Sea horizontal grid
   sn_dst_zgr = './domain_cfg.nc'                            ! Celtic Sea vertical grid
   sn_src_msk = './mesh_mask_from_AMM7.nc'    ! Wet-cell mask for the AMM7 grid
   sn_bathy   = './bathy_meter.nc'                           ! Celtic Sea bathymetry
   sn_nme_map = './grid_name_map_sco.json'                   ! Maps pyBDY names to NetCDF variables

!------------------------------------------------------------------------------
!  I/O
!------------------------------------------------------------------------------
   sn_src_dir      = './CMEMS.ncml'                          ! NcML file for the daily AMM7 data
   sn_dst_dir      = './output_dir'    ! Directory for the generated boundary files
   sn_fn           = 'CELTIC'                                ! Output filename prefix
   nn_fv           = -1e20                                   ! NetCDF fill value
   nn_src_time_adj = 0                                       ! Source time adjustment
   sn_dst_metainfo = 'AMM7 daily forcing for CELTIC8 GEG SF12' ! Output metadata

!------------------------------------------------------------------------------
!  unstructured open boundaries
!------------------------------------------------------------------------------
    ln_coords_file = .true.                                  ! Write boundary coordinates
    cn_coords_file = 'coordinates.bdy.nc'                    ! Boundary coordinate filename
    ln_mask_file   = .true.                                  ! Read the target boundary mask
    cn_mask_file   = './bdy_mask.nc'                         ! Target boundary mask filename
    ln_dyn2d       = .true.                                  ! Generate barotropic boundary fields
    ln_dyn3d       = .true.                                  ! Generate baroclinic velocity fields
    ln_tra         = .true.                                  ! Generate temperature and salinity fields
    ln_ice         = .false.                                 ! Generate ice boundary fields
    ln_zinterp     = .true.                                  ! Interpolate in the vertical
    nn_rimwidth    = 9                                       ! Width of the boundary relaxation zone

!------------------------------------------------------------------------------
!  unstructured open boundaries tidal parameters
!------------------------------------------------------------------------------
    ln_tide       = .false.                                  ! Tidal generation is disabled for this run
    sn_tide_model = 'FES2014'                                ! Used only when tidal generation is enabled
    ln_trans      = .true.                                   ! Interpolate transport rather than velocities

!------------------------------------------------------------------------------
!  Time information
!------------------------------------------------------------------------------
    sn_date_start         = '1993-01-01'                     ! Start date for boundary output
    sn_date_end           = '1994-01-01'                     ! End date for boundary output
    sn_dst_calendar       = 'gregorian'                      ! Output calendar
    sn_date_origin        = '1900-01-01'                     ! Reference date for the time axis
    ln_time_interpolation = .true.                           ! Enable time interpolation

!------------------------------------------------------------------------------
!  Additional parameters
!------------------------------------------------------------------------------
    nn_wei                  = 1                              ! Smoothing filter weights
    rn_r0                   = 0.041666666                    ! Gaussian smoothing distance in degrees
    sn_history              = 'AMM7 daily forcing for CELTIC8 GEG SF12' ! NetCDF history metadata
    ln_nemo3p4              = .true.                         ! Use NEMO 3.4 and later boundary file format
    nn_alpha                = 0                              ! Euler rotation angle
    nn_beta                 = 0                              ! Euler rotation angle
    nn_gamma                = 0                              ! Euler rotation angle
    rn_mask_max_depth       = 100.0                          ! Maximum depth to ignore for masking
    rn_mask_shelfbreak_dist = 20000.0                        ! Distance from the shelf break
