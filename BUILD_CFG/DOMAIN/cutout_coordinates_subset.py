#!/usr/bin/env python3

import xarray as xr


# ------------------------------
# Settings
# ------------------------------

# Parent AMM15 domain file
parent_file = "./GEG_SF12.nc"

# Output coordinate file
output_file = "./CelticS_coordinates_260410.nc"

# Cut-out indices (limit bathy to 200m )
imin = 500
imax = 925
jmin = 244
jmax = 555


# These are the horizontal coordinate and scale-factor variables
variables_to_copy = [
    "nav_lon", "nav_lat",
    "glamt", "gphit",
    "glamu", "gphiu",
    "glamv", "gphiv",
    "glamf", "gphif",
    "e1t", "e2t",
    "e1u", "e2u",
    "e1v", "e2v",
    "e1f", "e2f",
]


# ------------------------------
# Read parent file
# ------------------------------

print("Opening parent file:")
print(parent_file)

parent_ds = xr.open_dataset(parent_file)


# ------------------------------
# Create output dataset
# ------------------------------

# Make an empty dataset for the new coordinate file
new_ds = xr.Dataset()

# Copy the selected variables from the parent file
# nav_lon and nav_lat already have dimensions (y, x)
# The other variables have dimensions (t, y, x), so we use t=0
for var_name in variables_to_copy:
    print("Copying:", var_name)

    if var_name in ["nav_lon", "nav_lat"]:
        data = parent_ds[var_name].isel(
            y=slice(jmin, jmax + 1),
            x=slice(imin, imax + 1)
        )
    else:
        data = parent_ds[var_name].isel(
            t=0,
            y=slice(jmin, jmax + 1),
            x=slice(imin, imax + 1)
        )

    new_ds[var_name] = data

# ------------------------------
# Save output file
# ------------------------------

ny = new_ds.sizes["y"]
nx = new_ds.sizes["x"]

print("Writing output file:")
print(output_file)

new_ds.to_netcdf(output_file)


# ------------------------------
# Final message
# ------------------------------

print("Done")
print("Output shape:", ny, "x", nx)
print("imin =", imin)
print("imax =", imax)
print("jmin =", jmin)
print("jmax =", jmax)
