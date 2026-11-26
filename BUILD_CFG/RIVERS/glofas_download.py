import cdsapi
from pathlib import Path

dataset = "cems-glofas-historical"

OUT_DIR = Path("glofas_downloads")
OUT_DIR.mkdir(exist_ok=True)

YEARS = [str(year) for year in range(1993, 2026)]
 
base_request = {
    "system_version": ["version_4_0"],
    "hydrological_model": ["lisflood"],
    "product_type": ["consolidated"],
    "variable": ["river_discharge_in_the_last_24_hours"],
    "hmonth": [
        "01",
        "02",
        "03",
        "04",
        "05",
        "06",
        "07",
        "08",
        "09",
        "10",
        "11",
        "12"
    ],
    "hday": [
        "01",
        "02",
        "03",
        "04",
        "05",
        "06",
        "07",
        "08",
        "09",
        "10",
        "11",
        "12",
        "13",
        "14",
        "15",
        "16",
        "17",
        "18",
        "19",
        "20",
        "21",
        "22",
        "23",
        "24",
        "25",
        "26",
        "27",
        "28",
        "29",
        "30",
        "31"
    ],
    "data_format": "netcdf",
    "download_format": "zip",
    "area": [67, -30, 38, 18]
}

client = cdsapi.Client()

for year in YEARS:
    target = OUT_DIR / f"glofas_historical_{year}.zip"
    if target.exists():
        print(f"Skipping {year}: {target} already exists")
        continue

    request = base_request | {"hyear": [year]}
    print(f"Downloading {year} to {target}")
    client.retrieve(dataset, request).download(str(target))
