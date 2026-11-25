import sys
from pathlib import Path
sys.path.append("/home/users/binguo/IC/UK500_method/")

from calc_ini_ts import dep_3d_interpolate_lev, check_depths
import xarray as xr
import numpy as np


def active_t_mask(cfg, depth_dim):
    """Return True for active T points, using NEMO 1-based bottom_level."""
    bottom = cfg["bottom_level"]
    if "t" in bottom.dims:
        bottom = bottom.isel(t=0)

    levels = xr.DataArray(
        np.arange(cfg.sizes[depth_dim]) + 1,
        dims=(depth_dim,),
    )
    return levels <= bottom


def wet_zero_count(da, wet_mask):
    return int(((da == 0.0) & wet_mask).sum().item())

# paths
variables = ["votemper", "vosaline"]
case_dir = Path(__file__).resolve().parent
input_dir = case_dir / "input_data"
src_fn = input_dir / "19930101T0000Z_mersea.grid_T.nc"
src_cfg_fn = input_dir / "AMM7_domain_cfg_sub.nc"
src_cfg_depth0 = input_dir / "AMM7_domain_cfg_sub_with_gdept_0.nc"

cfg_fn = input_dir / "domain_cfg.nc"
cfg_fn_depth0 = input_dir / "domain_cfg_with_gdept_0.nc"
dst_fn = case_dir / "output" / "Celtic8_GEG_SF12_IC_y1993m01d01.nc"

first = True

# Open target grid once
cfg = xr.open_dataset(cfg_fn)
cfg = check_depths(cfg,cfg_fn_depth0 )
# open source cfg
src_cfg = xr.open_dataset(src_cfg_fn)
src_cfg = check_depths(src_cfg, src_cfg_depth0)

# rename vertical dimension to match source data
src_cfg = src_cfg.rename({"z": "deptht"})
src_wet = active_t_mask(src_cfg, "deptht")
tgt_wet = active_t_mask(cfg, "z")

for var in variables:
    print(f"Processing {var}", flush=True)

    # Open source variable and extract first time slice
    da = xr.open_dataset(src_fn)[var].isel(time_counter=0).squeeze(drop=True)
    da = da.where(src_wet)

    if var == "vosaline":
        # Source land/below-bottom cells are stored as exact zeros, not NaNs.
        # They must not participate in nearest-neighbour interpolation.
        da = da.where(da > 0.0)

    # Interpolate whole domain in one go
    out = dep_3d_interpolate_lev(da, cfg, src_cfg["gdept_0"])
    out = out.where(tgt_wet, 0.0)

    out.name = var
    zeros = wet_zero_count(out, tgt_wet)
    print(
        f"{var}: active-cell min={float(out.where(tgt_wet).min().item()):.6g}, "
        f"max={float(out.where(tgt_wet).max().item()):.6g}, "
        f"zero_count={zeros}",
        flush=True,
    )
    if zeros:
        raise ValueError(f"{var} still has {zeros} exact zeros in active target cells")

    if first:
        out.to_netcdf(dst_fn)
        first = False
        print(f"Generated NetCDF with first variable: {var}", flush=True)
    else:
        out.to_netcdf(dst_fn, mode="a")
        print(f"Added second variable: {var}", flush=True)

print("End of script", flush=True)
