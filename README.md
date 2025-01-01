# install requirements
run the following in an interactive julia session
```julia
using Pkg; Pkg.add(["CSV", "DataFrames", "JuMP", "SCIP"])
```

# get preferences csv file
- download csv from google sheets
- rename to preferences.csv, put into this folder (next to main.jl)

# run the script
```sh
julia main.jl
```
