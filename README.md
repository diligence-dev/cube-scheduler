# install requirements
run the following in an interactive julia session
```julia
using Pkg; Pkg.add(["CSV", "DataFrames", "JuMP", "SCIP", "HTTP"])
```

# get required files
- download preferences and registration csv from google forms/sheets
- rename to preferences.csv and registrations.csv, put into this folder (next to main.jl)

# run the script
```sh
julia main.jl
```
