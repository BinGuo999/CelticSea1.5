#!/usr/bin/env python3

import xarray as xr


# ------------------------------
# Settings
# ------------------------------

# Parent AMM15 domain file
parent_file = "./GEG_SF12.nc"

# Output bathymetry file
output_file = "./CelticS_bathy_meter.nc"

# Cut-out indices
imin = 500
imax = 925
jmin = 244
jmax = 555

# Fill value used for land points
fill_value = -9999.0


# ------------------------------
# Read parent file
# ------------------------------

print("Opening parent file:")
print(parent_file)

parent_ds = xr.open_dataset(parent_file)


# ------------------------------
# Extract cut-out data
# ------------------------------

print("Copying bathymetry and navigation variables")

bathy_data = parent_ds["bathy"].isel(
    t=0,
    y=slice(jmin, jmax + 1),
    x=slice(imin, imax + 1)
)

# Write land points as -9999 in the output bathymetry field.
bathy_data = bathy_data.where(bathy_data > 0, fill_value)

nav_lon_data = parent_ds["nav_lon"].isel(
    y=slice(jmin, jmax + 1),
    x=slice(imin, imax + 1)
)

nav_lat_data = parent_ds["nav_lat"].isel(
    y=slice(jmin, jmax + 1),
    x=slice(imin, imax + 1)
)


# ------------------------------
# Create output dataset
# ------------------------------

new_ds = xr.Dataset()

new_ds["Bathymetry"] = bathy_data.rename("Bathymetry")
new_ds["nav_lat"] = nav_lat_data
new_ds["nav_lon"] = nav_lon_data


# ------------------------------
# Add attributes
# ------------------------------

new_ds["Bathymetry"].attrs["missing_value"] = fill_value
new_ds["Bathymetry"].attrs["units"] = "meters"
new_ds["Bathymetry"].attrs["long_name"] = "Bathymetry"
new_ds["Bathymetry"].attrs["associate"] = "nav_lon nav_lat"

new_ds["nav_lat"].attrs["missing_value"] = fill_value
new_ds["nav_lat"].attrs["units"] = "degrees"
new_ds["nav_lat"].attrs["long_name"] = "Latitude North"
new_ds["nav_lat"].attrs["nav_model"] = "Default grid"

new_ds["nav_lon"].attrs["missing_value"] = fill_value
new_ds["nav_lon"].attrs["units"] = "degrees"
new_ds["nav_lon"].attrs["long_name"] = "Longitude East"
new_ds["nav_lon"].attrs["nav_model"] = "Default grid"


# ------------------------------
# Save output file
# ------------------------------

ny = new_ds.sizes["y"]
nx = new_ds.sizes["x"]

print("Writing output file:")
print(output_file)

encoding = {
    "Bathymetry": {"_FillValue": fill_value},
    "nav_lat": {"_FillValue": fill_value},
    "nav_lon": {"_FillValue": fill_value},
}

new_ds.to_netcdf(output_file, encoding=encoding)


# ------------------------------
# Final message
# ------------------------------

print("Done")
print("Output shape:", ny, "x", nx)
print("imin =", imin)
print("imax =", imax)
print("jmin =", jmin)
print("jmax =", jmax)
