# astro-introductions-2023

## Setup

Activate the repository root directory and instantiate the environment:

```julia-repl
julia>] activate
julia>] registry add https://github.com/JuliaRegistries/General
julia>] registry add https://github.com/astro-group-bristol/AstroRegistry
julia>] instantiate
```

## Usage

To generate a gif of a picture spinning around a black hole, rename your image to `./input.jpg` (else adjust the script), and run with

```bash
julia -tauto --project=. ./black-hole-face/run.jl
```

To generate the plot of Böögg Time to Explode versus temperature, along with the simple linear fit, simply run

```bash
julia --project=. ./boogg-plot/boogg.jl
```

## References

Sources used gather time to explode throughout the years:

- [SRF Super Sommer](https://www.srf.ch/news/regional/zuerich-schaffhausen/super-sommer-der-kopf-des-boeoeggs-ist-nach-7-23-weg)
- [SRF Sechselauten 2019](https://www.srf.ch/news/regional/zuerich-schaffhausen/sechselaeuten-2019-so-vertreibt-die-stadt-zuerich-den-winter)
- [SRF Der Boeoeggometer](https://www.srf.ch/radio-srf-1/radio-srf-1-wie-zuverlaessig-ist-der-boeoeggometer)

Meteorological data from MeteoSwiss:
```
Method: Begert M, Frei C. 2018. Long-term area-mean temperature series for Switzerland - Combining homogenized station data and high resolution grid data. Int. J. Climatol., 38: 2792-2807. https://doi.org/10.1002/joc.5460
Dataset: MeteoSwiss. Area-mean temperatures of Switzerland. doi:10.18751/Climate/Timeseries/CHTM/1.3
```