# CelticSea1.5
A 1.5 km regional NEMO configuration covers the Celtic Sea

## Download the repository

Download the full repository from [GitHub](https://github.com/BinGuo999/CelticSea1.5) using **Code → Download ZIP**, then extract it. Alternatively, clone it:

```bash
git clone https://github.com/BinGuo999/CelticSea1.5.git
```

In `Scripts/1.make_path.sh`, set `gituhb_download` to the absolute path of your downloaded or cloned repository. This directory contains `Scripts`, `MY_SRC`, and `CS1.5_NEMO_support`.

For example:

```bash
export gituhb_download=/epccfs/n01/n01/binguo/github_binguo999/CelticSea1.5-main
```

`gituhb_download` is the source repository location. `WORK` and `REPO` determine the separate build directory. Step 4 reads `gituhb_download` from `1.make_path.sh`.
