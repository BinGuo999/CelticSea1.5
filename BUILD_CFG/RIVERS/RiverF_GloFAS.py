#!/usr/bin/env python3
"""
Generate NEMO river runoff forcing from GloFAS discharge data.

GloFAS discharge is defined on the land routing grid. The local drainage
direction (LDD) file is used to identify coastal river outlet cells before
the discharge is mapped to the nearest NEMO coastal sea cell.

Outputs: 
  rorunoff(time_counter, y, x)
  units:  kg m-2 s-1

29/05/2026  - BinGuo 

"""


import argparse
import os

import numpy as np
from netCDF4 import Dataset


# =============================================================================
# Easy-to-change settings
# =============================================================================

RHO0 = 1000.0
YEAR_START = 1999
YEAR_END = 2025
THRESHOLD = 1500.0  # m3/s; rivers larger than this are spread over nearby sea cells
WRITE_DIAGNOSTICS = True  # True means that there will be some middle output to help for correct and understanding
# For example: coast_mask_top_level_CELTIC8.nc  ldd_outlet_check_CELTIC8.nc   large_river_spreading_CELTIC8.txt

GLOFAS_FILE = "/projectsa/UKCI/binguo/GloFAS_data/glofas_downloads/glofas_historical_{year}.nc"
LDD_FILE = "/projectsa/UKCI/binguo/GloFAS_data/glofas_downloads/ldd_glofas_v4_0_eAMM7_38N67N_30W18E.nc"
DOMAIN_FILE = "/work/binguo/River/CELTIC8_GEG_CF12/domain_cfg.nc"

DIAGNOSTICS_DIR = os.path.join(os.getcwd(), "Diagnostics")
COAST_MASK_DIAG_FILE = os.path.join(DIAGNOSTICS_DIR, "coast_mask_top_level_CELTIC8.nc")
LDD_OUTLET_DIAG_FILE = os.path.join(DIAGNOSTICS_DIR, "ldd_outlet_check_CELTIC8.nc")
LARGE_RIVER_DIAG_FILE = os.path.join(DIAGNOSTICS_DIR, "large_river_spreading_CELTIC8.txt")
COAST_RIVER_DIAG_FILE = os.path.join(DIAGNOSTICS_DIR, "coast_river_discharge_CELTIC8.nc")


# =============================================================================
# Small helper functions
# =============================================================================

def read_variable(nc, name, squeeze=True):
    """Read one NetCDF variable and convert masked values to NaN."""
    data = np.ma.asarray(nc.variables[name][:]).astype(float)
    data = np.ma.filled(data, np.nan)

    if squeeze:
        data = np.squeeze(data)

    return data


def wrap_longitude(lon):
    """Convert longitude values from 0..360 to -180..180 if needed."""
    lon = lon.copy()
    lon[lon > 180.0] -= 360.0
    return lon


def filename_for_year(filename_template, year):
    """Fill a filename template with the current year."""
    return filename_template.format(year=year)


def output_file_for_year(domain_file, output_template, year):
    """Create the output filename for one year."""
    if output_template is None:
        output_template = os.path.join(
            os.getcwd(),
            "rivers_CELTIC8_GloFAS_y{year}.nc",
        )

    return filename_for_year(output_template, year)


# =============================================================================
# Diagnostic output
# =============================================================================

def write_ldd_outlet_diagnostic(output_file, outlet, ocean_neighbour_count):
    """Write LDD outlet masks for manual checking."""
    output_dir = os.path.dirname(output_file)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with Dataset(output_file, "w", format="NETCDF4_CLASSIC") as nc:
        ny, nx = outlet.shape
        nc.createDimension("y", ny)
        nc.createDimension("x", nx)

        outlet_var = nc.createVariable("outlet", "i1", ("y", "x"))
        ocean_neighbour_var = nc.createVariable("ocean_neighbour_count", "i1", ("y", "x"))

        outlet_var[:, :] = outlet.astype(np.int8)
        ocean_neighbour_var[:, :] = ocean_neighbour_count.astype(np.int8)


def write_coast_mask_diagnostic(output_file, coast_mask, lon_region=None, lat_region=None):
    """Write NEMO coast mask for manual checking."""
    output_dir = os.path.dirname(output_file)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with Dataset(output_file, "w", format="NETCDF4_CLASSIC") as nc:
        ny, nx = coast_mask.shape
        nc.createDimension("y", ny)
        nc.createDimension("x", nx)

        mask = nc.createVariable("coast_mask", "f8", ("y", "x"), fill_value=np.nan)
        mask[:, :] = coast_mask

        if lon_region is not None and lat_region is not None:
            nav_lon = nc.createVariable("nav_lon", "f8", ("y", "x"))
            nav_lat = nc.createVariable("nav_lat", "f8", ("y", "x"))
            nav_lon[:, :] = lon_region
            nav_lat[:, :] = lat_region


def write_coast_river_diagnostic(
    output_file,
    lon_region,
    lat_region,
    coast_mask,
    river_discharge,
    valid_time,
):
    """Write coastline plus river discharge on the NEMO grid for checking."""
    output_dir = os.path.dirname(output_file)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    if os.path.exists(output_file):
        os.remove(output_file)

    nt, ny, nx = river_discharge.shape
    river_sum = np.nansum(river_discharge, axis=0)
    river_max = np.nanmax(river_discharge, axis=0)
    river_mean = np.nanmean(river_discharge, axis=0)
    river_active = (river_sum > 0.0).astype(np.int8)

    with Dataset(output_file, "w", format="NETCDF4_CLASSIC") as nc:
        nc.createDimension("time_counter", nt)
        nc.createDimension("y", ny)
        nc.createDimension("x", nx)

        time = nc.createVariable("time_counter", "f8", ("time_counter",))
        nav_lon = nc.createVariable("nav_lon", "f8", ("y", "x"))
        nav_lat = nc.createVariable("nav_lat", "f8", ("y", "x"))
        coast = nc.createVariable("coast_mask", "f8", ("y", "x"), fill_value=np.nan)
        active = nc.createVariable("river_active_mask", "i1", ("y", "x"))
        discharge = nc.createVariable("river_discharge", "f4", ("time_counter", "y", "x"))
        discharge_sum = nc.createVariable("river_discharge_sum", "f4", ("y", "x"))
        discharge_max = nc.createVariable("river_discharge_max", "f4", ("y", "x"))
        discharge_mean = nc.createVariable("river_discharge_mean", "f4", ("y", "x"))

        if valid_time is None or valid_time.shape[0] != nt:
            time[:] = np.arange(1, nt + 1)
        else:
            time[:] = valid_time

        nav_lon[:, :] = lon_region
        nav_lat[:, :] = lat_region
        coast[:, :] = coast_mask
        active[:, :] = river_active
        discharge[:, :, :] = river_discharge.astype(np.float32)
        discharge_sum[:, :] = river_sum.astype(np.float32)
        discharge_max[:, :] = river_max.astype(np.float32)
        discharge_mean[:, :] = river_mean.astype(np.float32)

        discharge.units = "m3 s-1"
        discharge_sum.units = "m3 s-1 summed over time steps"
        discharge_max.units = "m3 s-1"
        discharge_mean.units = "m3 s-1"
        coast.comment = "1 coastal sea cell, 0 non-coastal sea cell, NaN land"
        active.comment = "1 where river discharge is present in at least one time step"


def update_large_river_diagnostic(
    records,
    tt,
    y,
    x,
    radius,
    river,
    local_sum,
    number_of_sea_points,
    spread_value,
    lon_region,
    lat_region,
):
    """Collect one summary record for each large river grid point."""
    lon_value = np.nan
    lat_value = np.nan
    if lon_region is not None and lat_region is not None:
        lon_value = lon_region[y, x]
        lat_value = lat_region[y, x]

    key = (int(y), int(x))
    point_discharge = float(river[tt, y, x])

    if key not in records:
        records[key] = {
            "river_name": "unknown",
            "y": int(y),
            "x": int(x),
            "longitude": float(lon_value),
            "latitude": float(lat_value),
            "exceed_time_indices": set(),
            "max_time_index": tt + 1,
            "max_radius": radius,
            "max_point_discharge": point_discharge,
            "max_local_total": float(local_sum),
            "max_spread_points": int(number_of_sea_points),
            "max_spread_value": float(spread_value),
        }

    record = records[key]
    record["exceed_time_indices"].add(tt + 1)

    if point_discharge > record["max_point_discharge"]:
        record["max_time_index"] = tt + 1
        record["max_radius"] = radius
        record["max_point_discharge"] = point_discharge
        record["max_local_total"] = float(local_sum)
        record["max_spread_points"] = int(number_of_sea_points)
        record["max_spread_value"] = float(spread_value)


def write_large_river_diagnostic(diagnostic_file, records):
    """Write large river spreading summary to a readable text file."""
    output_dir = os.path.dirname(diagnostic_file)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with open(diagnostic_file, "w") as diag:
        diag.write(
            f"{'river_name':<14}"
            f"{'y':>7}"
            f"{'x':>7}"
            f"{'longitude':>14}"
            f"{'latitude':>14}"
            f"{'exceed_count':>15}"
            f"{'max_time':>11}"
            f"{'radius':>9}"
            f"{'max_point_m3_s':>18}"
            f"{'max_local_total_m3_s':>23}"
            f"{'spread_points':>16}"
            f"{'spread_each_m3_s':>20}\n"
        )
        diag.write("-" * 184 + "\n")

        records = sorted(
            records.values(),
            key=lambda item: item["max_point_discharge"],
            reverse=True,
        )

        for record in records:
            diag.write(
                f"{record['river_name']:<14}"
                f"{record['y']:>7d}"
                f"{record['x']:>7d}"
                f"{record['longitude']:>14.6f}"
                f"{record['latitude']:>14.6f}"
                f"{len(record['exceed_time_indices']):>15d}"
                f"{record['max_time_index']:>11d}"
                f"{record['max_radius']:>9d}"
                f"{record['max_point_discharge']:>18.6f}"
                f"{record['max_local_total']:>23.6f}"
                f"{record['max_spread_points']:>16d}"
                f"{record['max_spread_value']:>20.6f}\n"
            )


# =============================================================================
# Read input data
# =============================================================================

def read_domain(domain_file):
    """Read the NEMO domain grid."""
    with Dataset(domain_file) as nc:
        lon_region = read_variable(nc, "nav_lon")
        lat_region = read_variable(nc, "nav_lat")
        e1t_region = read_variable(nc, "e1t")
        e2t_region = read_variable(nc, "e2t")
        top_level = read_variable(nc, "top_level")

    return lon_region, lat_region, e1t_region, e2t_region, top_level


def read_glofas(glofas_file):
    """Read GloFAS discharge. Units are already m3/s."""
    with Dataset(glofas_file) as nc:
        lon = read_variable(nc, "longitude")
        lat = read_variable(nc, "latitude")
        discharge = read_variable(nc, "dis24", squeeze=False)
        valid_time = read_variable(nc, "valid_time")

    lon = wrap_longitude(lon)
    discharge[discharge <= 0.0] = np.nan

    return lon, lat, discharge, valid_time


def read_ldd(ldd_file):
    """Read local drainage direction data."""
    with Dataset(ldd_file) as nc:
        lon = read_variable(nc, "lon")
        lat = read_variable(nc, "lat")
        ldd = read_variable(nc, "ldd")

    lon = wrap_longitude(lon)

    return lon, lat, ldd


def check_glofas_ldd_grid(glofas_lon, glofas_lat, ldd_lon, ldd_lat):
    """Make sure the dynamic discharge and static LDD grids align."""
    if glofas_lon.shape != ldd_lon.shape or glofas_lat.shape != ldd_lat.shape:
        raise ValueError("GloFAS and LDD coordinate dimensions do not match")

    if not np.allclose(glofas_lon, ldd_lon, atol=1.0e-8, equal_nan=True):
        raise ValueError("GloFAS and LDD longitude coordinates do not match")

    if not np.allclose(glofas_lat, ldd_lat, atol=1.0e-8, equal_nan=True):
        raise ValueError("GloFAS and LDD latitude coordinates do not match")


def identify_ldd_ocean_outflows(ldd):
    """
    Identify coastal outlet cells on the GloFAS routing grid.

    LDD value 5 is a terminal cell. Keep only those terminal cells that touch
    ocean/no-data in the 8 neighbouring cells, excluding inland pits.
    """
    ocean = ~np.isfinite(ldd)
    outlet = ldd == 5

    padded_ocean = np.pad(ocean, ((1, 1), (1, 1)), mode="constant", constant_values=False)
    ocean_neighbour_count = (
        padded_ocean[:-2, 1:-1]   # north
        + padded_ocean[2:, 1:-1]  # south
        + padded_ocean[1:-1, :-2] # west
        + padded_ocean[1:-1, 2:]  # east
        + padded_ocean[:-2, :-2]  # northwest
        + padded_ocean[:-2, 2:]   # northeast
        + padded_ocean[2:, :-2]   # southwest
        + padded_ocean[2:, 2:]    # southeast
    )

    if WRITE_DIAGNOSTICS:
        write_ldd_outlet_diagnostic(LDD_OUTLET_DIAG_FILE, outlet, ocean_neighbour_count)

    return outlet & (ocean_neighbour_count > 0)


# =============================================================================
# Create the regional coastline mask
# =============================================================================

def make_coast_mask(top_level, lon_region=None, lat_region=None):
    """
    Find sea cells that touch land.
    Input value:
    0 = Land
    1 = ocean
    OBC also is 0


    Output values:
      1   = coastal sea point (the one cell that touch land)
      0   = non-coastal sea point
      NaN = land point
    """
    land_sea = top_level.astype(float)
    land_sea[land_sea == 0] = np.nan

    land = np.isnan(land_sea)
    sea = land_sea == 1

    # Count land neighbours to the north/south/east/west of each cell.
    padded_land = np.pad(land.astype(int), ((1, 1), (1, 1)), mode="edge")
    land_neighbour_count = (
        padded_land[:-2, 1:-1]
        + padded_land[2:, 1:-1]
        + padded_land[1:-1, :-2]
        + padded_land[1:-1, 2:]
    )

    coast = (land_neighbour_count > 0) & sea

    # Same as the MATLAB script: do not put rivers on the two-cell boundary.
    coast[:2, :] = False
    coast[-2:, :] = False
    coast[:, :2] = False
    coast[:, -2:] = False

    coast_mask = coast.astype(float)
    coast_mask[np.isnan(land_sea)] = np.nan

    if WRITE_DIAGNOSTICS:
        write_coast_mask_diagnostic(COAST_MASK_DIAG_FILE, coast_mask, lon_region, lat_region)

    return coast_mask


# =============================================================================
# Move GloFAS outlet cells to the regional coastline
# =============================================================================

def nearest_coast_index(river_points, coast_points):
    """
    For each river point, find the nearest coastline point.

    This is intentionally a simple chunked search. It avoids adding extra
    dependencies and matches MATLAB's first-minimum behaviour.
    """
    nearest = np.empty(river_points.shape[0], dtype=int)
    CHUNK_SIZE = 5000

    for start in range(0, river_points.shape[0], CHUNK_SIZE):
        stop = min(start + CHUNK_SIZE, river_points.shape[0])

        lon_difference = river_points[start:stop, None, 0] - coast_points[None, :, 0]
        lat_difference = river_points[start:stop, None, 1] - coast_points[None, :, 1]
        distance_squared = lon_difference**2 + lat_difference**2

        nearest[start:stop] = np.argmin(distance_squared, axis=1)

    return nearest


def remap_one_day(
    river_outflow,
    outflow_mask,
    source_lon,
    source_lat,
    coast_mask,
    lon_region,
    lat_region,
):
    """Move one day of GloFAS outlet discharge to the regional model coast."""

    ''' prepare an empty NEMO-grid array for one day's river Q.'''
    river_on_region = np.zeros_like(lon_region)

    # Keep only GloFAS coastal outlet points inside this regional domain.
    inside_domain = outflow_mask.copy()
    inside_domain &= source_lat <= np.nanmax(lat_region)
    inside_domain &= source_lat >= np.nanmin(lat_region)
    inside_domain &= source_lon <= np.nanmax(lon_region)
    inside_domain &= source_lon >= np.nanmin(lon_region)
    inside_domain &= np.isfinite(river_outflow)

    if not np.any(inside_domain):
        return river_on_region

    coast_y, coast_x = np.where(coast_mask == 1)
    coast_points = np.column_stack((lon_region[coast_y, coast_x], lat_region[coast_y, coast_x]))
    river_points = np.column_stack((source_lon[inside_domain], source_lat[inside_domain]))

    nearest = nearest_coast_index(river_points, coast_points)
    river_values = river_outflow[inside_domain]

    target_y = coast_y[nearest]
    target_x = coast_x[nearest]

    # Add together catchments that go to the same coast cell.
    np.add.at(river_on_region, (target_y, target_x), river_values)

    total_difference = np.nansum(river_values) - np.nansum(river_on_region)
    if total_difference > 1.0e-6:
        raise RuntimeError(f"Runoff was lost during remapping: {total_difference:g} m3/s")

    return river_on_region


# =============================================================================
# Spread very large rivers over nearby sea cells
# =============================================================================

def spread_large_rivers(
    river,
    sea_mask,
    threshold,
    quiet=False,
    lon_region=None,
    lat_region=None,
    diagnostic_file=None,
):
    """
    Spread large point-source rivers to nearby sea cells.

    river has dimensions:
      time, y, x
    """
    river = river.copy()
    nt, ny, nx = river.shape

    large_river_records = {}

    for tt in range(nt):
        total_before = np.nansum(river[tt])
        radius = 2

        while True:
            large_cells = np.argwhere(river[tt] > threshold)

            if large_cells.size == 0:
                break

            for y, x in large_cells:
                y0 = max(0, y - radius)
                y1 = min(ny, y + radius + 1)
                x0 = max(0, x - radius)
                x1 = min(nx, x + radius + 1)

                local_sea = sea_mask[y0:y1, x0:x1]
                number_of_sea_points = np.count_nonzero(local_sea)

                if number_of_sea_points == 0:
                    continue

                local_sum = np.nansum(river[tt, y0:y1, x0:x1])
                spread_value = local_sum / number_of_sea_points

                if diagnostic_file is not None:
                    update_large_river_diagnostic(
                        large_river_records,
                        tt,
                        y,
                        x,
                        radius,
                        river,
                        local_sum,
                        number_of_sea_points,
                        spread_value,
                        lon_region,
                        lat_region,
                    )

                river[tt, y0:y1, x0:x1][local_sea] = local_sum / number_of_sea_points

            radius += 1

            if not quiet:
                print(f"{radius} with time {tt + 1}")

        total_difference = total_before - np.nansum(river[tt])
        if total_difference > 1.0e-6:
            raise RuntimeError(f"Runoff was lost while spreading time {tt + 1}")

    if diagnostic_file is not None:
        write_large_river_diagnostic(diagnostic_file, large_river_records)

    return river


# =============================================================================
# Write output
# =============================================================================

def write_output(output_file, lon_region, lat_region, rorunoff, valid_time):
    """Write the final NEMO runoff file."""
    output_dir = os.path.dirname(output_file)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    if os.path.exists(output_file):
        os.remove(output_file)

    nt, ny, nx = rorunoff.shape

    with Dataset(output_file, "w", format="NETCDF4_CLASSIC") as nc:
        nc.createDimension("time_counter", None)
        nc.createDimension("y", ny)
        nc.createDimension("x", nx)

        time = nc.createVariable("time_counter", "f8", ("time_counter",))
        nav_lat = nc.createVariable("nav_lat", "f8", ("y", "x"))
        nav_lon = nc.createVariable("nav_lon", "f8", ("y", "x"))
        runoff = nc.createVariable("rorunoff", "f8", ("time_counter", "y", "x"))

        if valid_time is None or valid_time.shape[0] != nt:
            time[:] = np.arange(1, nt + 1)
        else:
            time[:] = valid_time

        nav_lat[:, :] = lat_region
        nav_lon[:, :] = lon_region
        runoff[:, :, :] = rorunoff

        time.long_name = "time"
        if valid_time is not None:
            time.units = "seconds since 1970-01-01"
            time.calendar = "proleptic_gregorian"

        runoff.long_name = "river runoff"
        runoff.units = "Kg m^-2 s^-1"


# =============================================================================
# Main workflow
# =============================================================================

def generate_river_forcing(args, year):
    """Run the whole river-forcing workflow."""
    glofas_file = filename_for_year(args.glofas_file, year)
    output_file = output_file_for_year(args.domain, args.output, year)

    if not os.path.exists(glofas_file):
        raise FileNotFoundError(glofas_file)

    print(f"Generating GloFAS river forcing for {year}")
    print(f"GloFAS: {glofas_file}")
    print(f"Output: {output_file}")

    lon_region, lat_region, e1t_region, e2t_region, top_level = read_domain(args.domain)
    coast_mask = make_coast_mask(top_level, lon_region, lat_region)
    sea_mask = np.isfinite(coast_mask)

    lon, lat, river_outflow, valid_time = read_glofas(glofas_file)
    ldd_lon, ldd_lat, ldd = read_ldd(args.ldd_file)
    check_glofas_ldd_grid(lon, lat, ldd_lon, ldd_lat)

    outflow_mask = identify_ldd_ocean_outflows(ldd)
    if not np.any(outflow_mask):
        raise RuntimeError("No LDD coastal outflow cells were identified")

    print(f"LDD=5 cells: {np.count_nonzero(ldd == 5)}")
    print(f"Coastal LDD outflow cells: {np.count_nonzero(outflow_mask)}")

    source_lon, source_lat = np.meshgrid(lon, lat)

    ''' Add a time dimension based on 2D grid of domain_cfg.nc '''
    nt = river_outflow.shape[0]
    river_on_region = np.empty((nt, *lon_region.shape))

    for tt in range(nt):
        river_on_region[tt] = remap_one_day(
            river_outflow[tt],
            outflow_mask,
            source_lon,
            source_lat,
            coast_mask,
            lon_region,
            lat_region,
        )
        if not args.quiet:
            print(tt + 1)

    river_on_region = spread_large_rivers(
        river_on_region,
        sea_mask,
        args.threshold,
        quiet=args.quiet,
        lon_region=lon_region,
        lat_region=lat_region,
        diagnostic_file=LARGE_RIVER_DIAG_FILE if WRITE_DIAGNOSTICS else None,
    )

    if WRITE_DIAGNOSTICS:
        write_coast_river_diagnostic(
            COAST_RIVER_DIAG_FILE,
            lon_region,
            lat_region,
            coast_mask,
            river_on_region,
            valid_time,
        )

    # Convert from m3/s to kg m-2 s-1, which is what NEMO expects.
    rorunoff = river_on_region * RHO0 / (e1t_region[None, :, :] * e2t_region[None, :, :])
    rorunoff[~np.isfinite(rorunoff)] = 0.0

    write_output(output_file, lon_region, lat_region, rorunoff, valid_time)


def parse_args():
    # function that args object
    # reads options from the command line, either use the defalut setting on the top of this script or from outside
    # for example: python generate_riverF.py --year 2019
    parser = argparse.ArgumentParser(description="Generate NEMO river forcing from GloFAS.")
    parser.add_argument("--year-start", type=int, default=YEAR_START)
    parser.add_argument("--year-end", type=int, default=YEAR_END)
    parser.add_argument("--domain", default=DOMAIN_FILE)
    parser.add_argument("--glofas-file", default=GLOFAS_FILE)
    parser.add_argument("--ldd-file", default=LDD_FILE)
    parser.add_argument("--threshold", type=float, default=THRESHOLD)
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--output", default=None)

    args = parser.parse_args()

    if args.year_end < args.year_start:
        raise ValueError("year-end must be greater than or equal to year-start")

    if args.year_end > args.year_start and "{year}" not in args.glofas_file:
        raise ValueError("glofas-file must contain {year} for multi-year runs")

    if args.year_end > args.year_start and args.output is not None and "{year}" not in args.output:
        raise ValueError("output must contain {year} for multi-year runs")

    if not os.path.exists(args.domain):
        raise FileNotFoundError(args.domain)

    if not os.path.exists(args.ldd_file):
        raise FileNotFoundError(args.ldd_file)

    print(f"Generating GloFAS river forcing from {args.year_start} to {args.year_end}")
    print(f"GloFAS template: {args.glofas_file}")
    print(f"LDD: {args.ldd_file}")
    if WRITE_DIAGNOSTICS:
        print(f"Coast mask diagnostic: {COAST_MASK_DIAG_FILE}")
        print(f"LDD outlet diagnostic: {LDD_OUTLET_DIAG_FILE}")
        print(f"Large river diagnostic: {LARGE_RIVER_DIAG_FILE}")
        print(f"Coast river diagnostic: {COAST_RIVER_DIAG_FILE}")
    print(f"Output template: {output_file_for_year(args.domain, args.output, '{year}')}")

    return args


if __name__ == "__main__":
    parsed_args = parse_args()
    for year in range(parsed_args.year_start, parsed_args.year_end + 1):
        generate_river_forcing(parsed_args, year)
