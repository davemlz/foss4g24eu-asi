using Pkg
Pkg.activate(".")
Pkg.instantiate()
using SpectralIndices

#### Check that we are using v0.2.0 of SpectralIndices

# this tutorial closely follows the SpectralIndices.jl documentation.
# It provides a gentle walk through of all the features of the package in
# an incremental fashion.

# Introduction to Indices Calculation
# we want to calculate the NDVI. Let's create the variables needed for this

nir = 6723
red = 1243

# Now let's explore the NDVI by simply calling it in the repl

NDVI

# as we can see all useful information is already there! 
# What's more is that this struct also acts as a callable function

NDVI(nir, red)

# Pretty neat stuff, although I wouldnt' recommend using this as your primary mode
# of calculating indices. If you still want to use it make sure the order of the parameters
# matches how they appear in the `bands` field of the index:

NDVI.bands

# A more flexible way to calculate indices is through the `compute` function.
# This function accepts the `SpectralIndex` struct and parameters as
# either a dictionary or keyword arguments:

params = Dict(
    "N" => nir,
    "R" => red
)
ndvi = compute(NDVI, params)

# Note that the keys in the Dic thave to match the band namesas they are spelled out
# in the `bands` field.
# Let's try with kwargs

ndvi = compute(NDVI; N=nir, R=red)

# Order of keyword arguments does not affect the outcome:

ndvi1 = compute(NDVI; N=nir, R=red)
ndvi2 = compute(NDVI; R=red, N=nir)
ndvi1 == ndvi2

# Suggested approach: compute_index

params = Dict(
    "N" => nir,
    "R" => red
)
ndvi = compute_index("NDVI", params)

ndvi = compute_index("NDVI"; N=nir, R=red)

# Quick sidenote on implementation details

function ndvi_funcstring_eval(N, R; string_formula = "(N-R)/(N+R)")
    formula_with_values = replace(string_formula, "N" => "($N)", "R" => "($R)")
    expr = Meta.parse(formula_with_values)
    result = eval(expr)
    return result
end

function ndvi_funcstring_il(N, R; string_formula = "(N-R)/(N+R)")
    func_str = "f(N, R) = $string_formula"    
    expr = Meta.parse(func_str)
    eval(expr)
    result = Base.invokelatest(f, N, R)    
    return result
end

ndvi_pure(N, R) = (N-R)/(N+R)

using BenchmarkTools

@benchmark ndvi_funcstring_eval(0.2, 0.1)
@benchmark ndvi_funcstring_il(0.2, 0.1)
@benchmark ndvi_pure(0.2, 0.1)

# As we can see the pure julia function as virtually no overhead, showing
# - zero memory allocations
# - nanosecond-level execution time

# The function based on eval shows:
# - efficient runtime evaluation of the function
# - usable microsecond range
# - this method is not usable in the context of a package, due to the world age problem

# The function with invokelast solves the world age problem but:
# - Has the highest overhead in terms of both execution time and memory usage
# - Scales poorly for large quantites of data

# Extending the examples: a new index and floats

SAVI
SAVI.bands

# The `L` parameter is new in this example.
# Thankfully, SpectralIndices.jl provides a list of constant values
# handy that we can leverage in this situation:

constants["L"]

# now that we know what L is, let's proceed with the calculation.
# SAVI needs input data to be between -1 and 1

nir /= 10000
red /= 10000

# now we can proceed as before

savi = compute(SAVI, Dict(
    "N" => nir,
    "R" => red,
    "L" => 0.5
))

savi = compute(SAVI; N=nir, R=red, L=0.5)

# Or, using the suggested compute_index:

savi = compute_index("SAVI", Dict(
    "N" => nir,
    "R" => red,
    "L" => 0.5)
)

savi = compute_index("SAVI"; N=nir, R=red, L=0.5)

# Now that we have introduced multiple indices let's see how we can compute
# multiple indiices at the same time:

params = Dict(
    "N" => nir,
    "R" => red,
    "L" => 0.5
)

ndvi, savi = compute_index(["NDVI", "SAVI"], params)

ndvi, savi = compute_index(["NDVI", "SAVI"]; N=nir, R=red, L=0.5)

# All of this can be extended to vectors as well:

params = Dict(
    "N" => fill(nir, 10),
    "R" => fill(red, 10),
    "L" => fill(0.5, 10)
)

ndvi, savi = compute_index(["NDVI", "SAVI"], params)

# We can use the same params to calculate single indices.
# The additional bands are just going to be ignored:

ndvi = compute_index("NDVI", params)
savi = compute_index("SAVI", params)

# Using kwargs is also still straightforward as before

ndvi, savi = compute_index(["NDVI", "SAVI"];
    N=fill(nir, 10),
    R=fill(red, 10),
    L=fill(0.5, 10))

ndvi = compute_index("NDVI";
    N=fill(nir, 10),
    R=fill(red, 10),
    L=fill(0.5, 10))

savi = compute_index("SAVI";
    N=fill(nir, 10),
    R=fill(red, 10),
    L=fill(0.5, 10))

# Using DataFrames.jl

using DataFrames

# Of course you probably will not be using single values to calculate your indices!
# This section illustrates how you can use SpectralIndices in conjuction with DataFrames.jl

# Let's load some data to use in the examples

df = load_dataset("spectral", DataFrame)

# Each column of this dataset is the Surface Reflectance from Landsat 8
# for 3 different classes. The samples were taken over Oporto.
# The data is taken from [spyndex](https://spyndex.readthedocs.io/en/latest/tutorials/pandas.html)
# This dataset specifically contains three different classes:

unique(df[!, "class"])

# so to reflect that we are going to calculate three different indices:
# `NDVI` for `vegetation`, `NDWI` for `water` and `NDBI` for `urban`.
# Let's see what bands we need:

NDVI.bands
NDWI.bands
NDBI.bands

# We need Green, Red, NIR and SWIR1 bands
# Since the `compute_index` expects the bands to have the same name
# as the have in the `bands` field we need to select the specific columns
# that we want out of the dataset and rename them.
# We can do this easily with `select`:

params = select(df, :SR_B3=>:G, :SR_B4=>:R, :SR_B5=>:N, :SR_B6=>:S1)

# Now our dataset is ready, and we just need to call the `compute_index` function

idx = compute_index(["NDVI", "NDWI", "NDBI"], params)

# Another way to obtain this is to feed single `DataFrame`s as kwargs.
# First we need to define the single `DataFrame`s:

idx = compute_index(["NDVI", "NDWI", "NDBI"]; 
    G = select(df, :SR_B3=>:G),
    N = select(df, :SR_B5=>:N),
    R = select(df, :SR_B4=>:R),
    S1 = select(df, :SR_B6=>:S1)
)

#Alternatively you can define a `Dict` for the indices from the `DataFrame`

params = Dict(
    "G" => df[!, "SR_B3"],
    "N" => df[!, "SR_B5"],
    "R" => df[!, "SR_B4"],
    "S1" => df[!, "SR_B6"]
)

ndvi, ndwi, ndbi = compute_index(["NDVI", "NDWI", "NDBI"], params)

# Just be careful with the naming, SpectralIndices.jl brings into the
# namespace all the indices as defined in `indices`. 
# The all caps version of the indices is reserved for them

# Again, we can just feed the single dataframes as kwargs

ndvi, ndwi, ndbi = compute_index(["NDVI", "NDWI", "NDBI"]; 
    G = df[!, "SR_B3"],
    N = df[!, "SR_B5"],
    R = df[!, "SR_B4"],
    S1 = df[!, "SR_B6"]
)

# The difference is that using these two approaches will result in an array

# Using YAXArrays.jl

using YAXArrays, DimensionalData

# As before let's load some data

yaxa = load_dataset("sentinel", YAXArray)

# We have a `YAXArray` object with three dimensions: `bands`, `x` and `y`.
# Each band is one of the 10 m spectral bands of a Sentinel-2 image.
# Data again taken from spyndex

# The data is stored as `Int64`, so let us convert it to `Float` and rescale it:

yaxa = yaxa./10000

# Now let's compute the NDVI for this dataset!

ndvi = compute_index("NDVI";
    N=yaxa[bands = At("B08")],
    R=yaxa[bands = At("B04")]
)

# Alternatively we can build a custom YAXArrays and feed that into the function

index_R = findfirst(yaxa.bands.val .== "B04")
index_N = findfirst(yaxa.bands.val .== "B08")
new_bands_dim = Dim{:Variables}(["R", "N"])

nr_data = cat(yaxa[:, :, index_R], yaxa[:, :, index_N], dims=3)
new_yaxa = YAXArray((yaxa.x, yaxa.y, new_bands_dim), nr_data)

# ATT! Please notice how the `Dim` is called `Variables`.
# This is needed for the internal computation to work properly.

ndvi = compute_index("NDVI", new_yaxa)

# Computing Kernels
# We want to compute the kNDVI for a `YAXArray`. 

kNDVI

# As we see from `bands` we need the `kNN` and `kNR`.
# In order to compute these values SpectralIndices.jl provides a
# `compute_kernel` function.
# If you are curious about the `kNDVI` remember that you always have the
# source of the index in the `reference` field:

kNDVI.reference

# Now that we are up to speed with the literature let's get to the computin'

knn = YAXArray((yaxa.x, yaxa.y), fill(1.0, 300, 300))
knr = compute_kernel(
    RBF;
    a = Float64.(yaxa[bands = At("B08")]),
    b = Float64.(yaxa[bands = At("B04")]),
    sigma = yaxa[bands = At("B08")].+yaxa[bands = At("B04")] ./ 2
)

# As always, you can decide to build an `YAXArray` and feed that to the 
# `compute_kernel` function if you prefer:

a = Float64.(yaxa[bands = At("B08")])
b = Float64.(yaxa[bands = At("B04")])
sigma = yaxa[bands = At("B08")].+yaxa[bands = At("B04")] ./ 2
kernel_dims = Dim{:Variables}(["a", "b", "sigma"])

params = concatenatecubes([a, b, sigma], kernel_dims)

knr = compute_kernel(RBF, params)

# We can finally compute the kNDVI:

kndvi = compute_index("kNDVI"; kNN = knn, kNR=knr)

# and we can also plot it

using GLMakie
fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1])
image!(ax, kndvi.data, colormap=:haline)
ylims!(300, 0)
fig