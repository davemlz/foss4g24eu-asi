/*
==========================
ASI in Google Earth Engine
==========================

spectral module: https://github.com/awesome-spectral-indices/spectral -> Paper: https://doi.org/10.5194/isprs-archives-XLVIII-4-W1-2022-301-2022
Awesome Spectral Indices: https://github.com/awesome-spectral-indices/awesome-spectral-indices

This notebook is divided as follows:

Part 1. Exploring spectral indices
Part 2. Computing spectral indices
Part 3. Computing multiple spectral indices
Part 4. Mapping spectral indices

LINK TO THIS NOTEBOOK IN THE CODE EDITOR: https://code.earthengine.google.com/67f27d91c4fc905aa55e0df9d3d113d8

*/

/*
-------------------------------------
Part 1: Exploring spectral indices
-------------------------------------
*/

// REQUIRE THE SPECTRAL MODULE
var spectral = require("users/dmlmont/spectral:spectral");

// PRINT ALL AVAILABLE SPECTRAL INDICES
print('Spectral Indices',spectral.indices);

// PRINT ATTRIBUTES OF AN INDEX USING DOT NOTATION
print('Attributes of NDVI',spectral.indices.NDVI);

// PRINT ATTRIBUTES OF AN INDEX USING KEYS
print('Attributes of SAVI',spectral.indices["SAVI"]);

// PRINT SPECIFIC ATTRIBUTES OF AN INDEX
print('Reference of BAIS2',spectral.indices.BAIS2.long_name);
print('Type of BAIS2',spectral.indices.BAIS2.type);
print('Formula of BAIS2',spectral.indices.BAIS2.formula);
print('Required bands of BAIS2',spectral.indices.BAIS2.bands);
print('Reference of BAIS2',spectral.indices.BAIS2.reference);
print('Contributor of BAIS2',spectral.indices.BAIS2.contributor);

// PRINT THE DESCRIPTION OF VARIABLES: BANDS AND ADDITIONAL PARAMETERS
print('Parameters Description',spectral.bands);

// PRINT THE DEFAULT VALUES OF THE ADDITIONAL PARAMETERS
print('Additional Parameters',spectral.constants);

// PRINT ALL SCALE PARAMETERS
print('All Scale Parameters',spectral.scaleParameters);

// PRINT ALL OFFSET PARAMETERS
print('All Offset Parameters',spectral.offsetParameters);

/*
-------------------------------------
Part 2: Computing spectral indices
-------------------------------------
*/

// REQUIRE THE PALETTES MODULE
var palettes = require('users/gena/packages:palettes');

// HALINE PALETTE
var haline = palettes.cmocean.Haline[7];

// LOCATION OF INTEREST
var tartu = ee.Geometry.Point([26.72636,58.37224]);

// DATASET TO USE: SENTINEL-2 SR
var dataset = 'COPERNICUS/S2_SR_HARMONIZED';

// FILTER THE DATASET
var S2 = ee.ImageCollection(dataset)
  .filterBounds(tartu)
  .filterDate('2020-06-01','2021-07-01')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',20))
  .first();
  
// SCALE THE IMAGE
var S2 = spectral.scale(S2,dataset);


// REQUIRED PARAMETERS ACCORDING TO THE REQUIRED BANDS
var parameters = {
  "N": S2.select("B8"),
  "R": S2.select("B4")
};

// COMPUTE THE NDVI
var S2_NDVI = spectral.computeIndex(S2,"NDVI",parameters);

// CHECK THE NEW BAND: NDVI
print("New band added: NDVI",S2_NDVI.bandNames());

// ADD THE NEW BAND TO THE MAP
Map.addLayer(S2_NDVI,{"min":0,"max":1,"bands":"NDVI","palette":haline},"NDVI");
Map.centerObject(S2_NDVI);

/*
-------------------------------------------
Part 3: Computing multiple spectral indices
-------------------------------------------
*/

// REQUIRED PARAMETERS ACCORDING TO THE REQUIRED BANDS
var parameters = {
  "N": S2.select("B8"),
  "R": S2.select("B4"),
  "L": 0.5, // Default Canopy Background for SAVI
};

// COMPUTE THE NIRv and SAVI
var S2_NIRv_SAVI = spectral.computeIndex(S2,["NIRv","SAVI"],parameters);

// CHECK THE NEW BANDS: NIRv, SAVI
print("New bands added: NIRv, SAVI",S2_NIRv_SAVI.bandNames());

// ADD THE NEW BAND TO THE MAP
Map.addLayer(S2_NIRv_SAVI,{"min":0,"max":0.7,"bands":"NIRv","palette":haline},"NIRv");
Map.addLayer(S2_NIRv_SAVI,{"min":0,"max":1,"bands":"SAVI","palette":haline},"SAVI");
Map.centerObject(S2_NIRv_SAVI);

/*
-------------------------------------------
Part 4: Mapping spectral indices
-------------------------------------------
*/

// DATASET TO USE: SENTINEL-2 SR
var dataset = 'COPERNICUS/S2_SR_HARMONIZED';

// FUNCTION TO MAP OVER AN IMAGE COLLECTION
function addIndices(img) {
  
  // SCALE THE IMAGE
  img = spectral.scale(img,dataset);
  
  // REQUIRED PARAMETERS ACCORDING TO THE REQUIRED BANDS
  var parameters = {
    "N": img.select("B8"),
    "R": img.select("B4"),
    "RE1": img.select("B5"),
    "RE2": img.select("B6"),
    "RE3": img.select("B7"),
  };
  
  // COMPUTE THE NDVI, GNDVI and SeLI
  return spectral.computeIndex(img,["IRECI","NDVI"],parameters);
  
}

// AREA TO REDUCE
var tartu_buffer = tartu.buffer(1000);

// FILTER THE DATASET AND COMPUTE THE INDICES
var S2 = ee.ImageCollection(dataset)
  .filterBounds(tartu_buffer)
  .filterDate('2018-01-01','2021-01-01')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',20))
  .map(addIndices); // Mapping indices
  
// CENTER MAP
Map.centerObject(tartu_buffer);

// CREATE TIME SERIES
var ts = ui.Chart.image.series({
  imageCollection: S2.select(["IRECI","NDVI"]),
  region: tartu_buffer,
  reducer: ee.Reducer.median(),
  scale: 10,
  xProperty: "system:time_start"
});

// PRINT TIME SERIES
print("TIME SERIES",ts);