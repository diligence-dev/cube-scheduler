# what is this?
I developed this tool to calculate the optimal schedule (who plays which cube in which time slot) for a MtG cube event for 48 people, who gave their preferences which of the 16 available cubes they'd like to play most, second most, etc.
There's also the option to generate an html document with a mailto link for each player so you can easily send mails to all participants which cube they play and when (the template is in generate_mails.jl).

To calculate the optimal schedule a 0-1 ILP (integer linear program) is created in julia (great programming language!) and JuMP and then solved using the SCIP solver. This is not only useful for cube, it can also be adapted to e.g. a boardgame event where you have 10 boardgames for different player counts available and want to match players to the boardgames they want to play most.

# install requirements
run the following in an interactive julia session
```julia
using Pkg; Pkg.add(["CSV", "DataFrames", "JuMP", "SCIP", "HTTP"])
```

# get required files
you need the following csv files with the given columns:
- cubes.csv: name,url
- registrations.csv: timestamp,mail_address,name
- preferences.csv: timestamp,mail_address,first_pick,second_pick,third_pick,fourth_pick,fifth_pick

# run the script
Go through main.jl and check if assumptions/configurations fit for you. You might want to change `rank_to_score = [20, 17, 16, 12, 11]` and almost certainly `top8_cube = "No Free Lunch Cube"`. You might want to comment in / adjust the constraint "a cube cannot be played in slot 1 and 2 (both on Saturday)". There's also a (currently commented out) constraint to prevent two players from playing together that could easily be adapted to ensure two players always play together. The whole thing is pretty flexible, so many things can be accomplished by adding a couple new constraints/variables or changing the objective function! My workflow was to open the script in vscode and interactively (ctrl + p) run parts of the script over and over.

```sh
julia main.jl
```

# want to use this for your event?
Feel free to contact me, I'd happily help with setting this up for your use case. I'd love this to be useful for other events!
