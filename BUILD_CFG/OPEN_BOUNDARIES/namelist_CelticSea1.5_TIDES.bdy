!!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
!! NEMO/OPA  : namelist for BDY generation tool
!!            
!!             User inputs for generating open boundary conditions
!!             employed by the BDY module in NEMO. Boundary data
!!             can be set up for v3.2 NEMO and above.
!!            
!!             More info here.....
!!            
!!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
!------------------------------------------------------------------------------
!   vertical coordinate
!------------------------------------------------------------------------------
   sn_src_zgr_type = 'sco' ! vertical coordinate type: 'zco', 'zps' or 'sco'
   sn_dst_zgr_type = 'sco' ! vertical coordinate type: 'zco', 'zps' or 'sco'
                           ! 'zco' is z-coordinate - full    steps
                           ! 'zps' is z-coordinate - partial steps
                           ! 'sco' is s- or hybrid z-s-coordinate

!------------------------------------------------------------------------------
!  grid information
!------------------------------------------------------------------------------
   sn_src_hgr = './AMM7_domain_cfg.nc'  ! domain cut from AMM7 parent /grid/   
   sn_src_zgr = './AMM7_domain_cfg.nc'   ! domain parent
   sn_dst_hgr = './domain_cfg.nc'    !  ! child
   sn_dst_zgr = './domain_cfg.nc' ! rename output variables
   sn_src_msk = './mesh_mask_from_AMM7.nc' ! derived from AMM7domain domain_cfg.nc       ! parent   
   sn_bathy   = './bathy_meter.nc'  !       ! child
   sn_nme_map = './grid_name_map_sco.json'     ! json file mapping variable names to netcdf vars

!------------------------------------------------------------------------------
!  I/O 
!------------------------------------------------------------------------------
   sn_src_dir      = './CMEMS.ncml'
   sn_dst_dir      = './output_tides/'
   sn_fn      = 'CELTIC'             ! prefix for output files
   nn_fv      = -1e20                 !  set fill value for output files
   nn_src_time_adj = 0                ! src time adjustment
   sn_dst_metainfo = 'CMEMS example'

!------------------------------------------------------------------------------
!  unstructured open boundaries                         
!------------------------------------------------------------------------------
    ln_coords_file = .true.               !  =T : produce bdy coordinates files
    cn_coords_file = 'coordinates.bdy.nc' !  name of bdy coordinates files 
                                          !  (if ln_coords_file=.TRUE.)
    ln_mask_file   = .true.              !  =T : read mask from file
    cn_mask_file   = './bdy_mask.nc'            !  name of mask file
                                          !  (if ln_mask_file=.TRUE.)
    ln_dyn2d       = .false.             !  boundary conditions for
                                          !  barotropic fields
    ln_dyn3d       = .false.             !  boundary conditions for
                                          !  baroclinic velocities
    ln_tra         = .false.              !  boundary conditions for T and S
    ln_ice         = .false.              !  ice boundary condition
    ln_zinterp     = .true.               !  vertical interpolation   
    nn_rimwidth    = 9                    !  width of the relaxation zone

!------------------------------------------------------------------------------
!  unstructured open boundaries tidal parameters                        
!------------------------------------------------------------------------------
    ln_tide        = .true.              !  =T : produce bdy tidal conditions
    sn_tide_model  = 'FES2014'            !  Name of tidal model (FES2014|TPXO7p2)      
    clname(1)      = 'M2'                 !  constituent name
    clname(2)      = 'S2'
    clname(3)      = 'N2'
    clname(4)      = 'O1'
    clname(5)      = 'K1'
    clname(6)      = 'K2'
    clname(7)      = 'L2'
    clname(8)      = 'NU2'
    clname(9)      = 'M4'
    clname(10)     = 'MS4'
    clname(11)     = 'Q1'
    clname(12)     = 'P1'
    clname(13)     = 'S1'
    clname(14)     = '2N2'
    clname(15)     = 'MU2'
    clname(16)     = 'EPS2'
    clname(17)     = 'J1'
    clname(18)     = 'M3'
    clname(19)     = 'M6'
    clname(20)     = 'M8'
    clname(21)     = 'MF'
    clname(22)     = 'MM'
    clname(23)     = 'MN4'
    clname(24)     = 'MSF'
    ln_trans       = .true.                !  interpolate transport rather than velocities
	! location of TPXO7.2 data
	sn_tide_grid_7p2   = '/work/n01/n01/binguo/pyBDY/inputs/tpxo7.2/grid_tpxo7.2.nc'
	sn_tide_h          = '/work/n01/n01/binguo/pyBDY/inputs/tpxo7.2/h_tpxo7.2.nc'
	sn_tide_u          = '/work/n01/n01/binguo/pyBDY/inputs/tpxo7.2/u_tpxo7.2.nc'
	! location of TPXO9v5 data: single constituents per file
	sn_tide_grid_9p5   = '/work/n01/n01/binguo/pyBDY/inputs/TPXO9_atlas_v5_nc/grid_tpxo9_atlas_30_v5.nc'
	sn_tide_dir        = '/work/n01/n01/binguo/pyBDY/inputs/TPXO9_atlas_v5_nc/'
	! location of FES2014 data
	sn_tide_fes        = '/work/n01/n01/binguo/pyBDY/inputs/FES2014/'
!------------------------------------------------------------------------------
!  Time information
!------------------------------------------------------------------------------
    sn_date_start   = '1993-01-01'    !  dst output date start YYYY-MM-DD
    sn_date_end     = '1994-01-01'    !  dst output date end YYYY-MM-DD
    sn_dst_calendar = 'gregorian' !  output calendar format
    sn_date_origin    = '1900-01-01'        !  base year for time counter
    ln_time_interpolation = .true. !  set to false to use parent
	
!------------------------------------------------------------------------------
!  Additional parameters
!------------------------------------------------------------------------------
    nn_wei  = 1                   !  smoothing filter weights 
    rn_r0   = 0.041666666         !  decorrelation distance use in gauss
                                  !  smoothing onto dst points. Need to 
                                  !  make this a funct. of dlon
    sn_history  = 'Test BDY generation with jeff's working tide version'
                                  !  history for netcdf file
    ln_nemo3p4  = .true.          !  else presume v3.2 or v3.3
    nn_alpha    = 0               !  Euler rotation angle
    nn_beta     = 0               !  Euler rotation angle
    nn_gamma    = 0               !  Euler rotation angle
	rn_mask_max_depth = 100.0     !  Maximum depth to be ignored for the mask
	rn_mask_shelfbreak_dist = 20000.0 !  Distance from the shelf break
