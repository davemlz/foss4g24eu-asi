# Opening Pandora's Spectral Box: Pioneering the Awesome Spectral Indices Suite
## FOSS4G Europe 2024, Tartu, Estonia, 07-02, 14:00–16:00 (Europe/Tallinn), Room 335

This repository contains the notebooks of the "Opening Pandora's Spectral Box: Pioneering the Awesome Spectral Indices Suite" workshop, led by [David Montero Loaiza](https://github.com/davemlz) and [Francesco Martinuzzi](https://martinuzzifrancesco.github.io/) from the [Remote Sensing Centre for Earth System Research (RSC4Earth), Leipzig University, Germany](https://rsc4earth.de/).

### Python

For running the notebooks, please run the following lines in your environment:

```
git clone https://github.com/davemlz/foss4g24eu-asi.git
cd foss4g24eu-asi
pip install -r requirements.txt
```

The notebooks can be found at the `notebooks` folder.

### Google Earth Engine (GEE) Code Editor (JavaScript)

For running the GEE notebook, please set up an account in [Google Earth Engine](https://earthengine.google.com/). The scripts will be run in the [JavaScript Code Editor](https://code.earthengine.google.com/).

### Julia

For Julia we suggest using the provided notebook `julia/SpectralIndicesjl.ipynb` in google colab. Instructions on how to run the session with Julia are included in the notebook. Alternatively, if you have a local installation of Julia you can run the following:
```
git clone https://github.com/davemlz/foss4g24eu-asi.git
cd foss4g24eu-asi
cd julia
julia requirements.jl
```
This way you can follow the presentation with the file `handson.jl`. We strongly suggest using Visual Studio Code with the Julia extension installed to have a smooth experience.

Note that the local installation of a Julia notebook is a bit trickier, so we do not suggest that in order to follow this workshop.