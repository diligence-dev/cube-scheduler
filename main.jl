using JuMP
using SCIP

# Define the sets
players = 1:48
slots = 1:3
cubes = 1:20

# Define the parameters
score = rand(length(players), length(cubes))  # Replace with actual score data

# Create the model
model = Model(SCIP.Optimizer)

# Define the variables
@variable(model, cs[c in cubes, s in slots], Bin)
@variable(model, pcs[p in players, c in cubes, s in slots], Bin)

# Define the constraints
@constraint(model, [c in cubes, s in slots], 8 * cs[c, s] == sum(pcs[p, c, s] for p in players))
@constraint(model, [p in players, s in slots], sum(pcs[p, c, s] for c in cubes) == 1)

# Define the objective
@objective(model, Max, sum(pcs[p, c, s] * score[p, c] for p in players, c in cubes, s in slots))

# Solve the model
optimize!(model)

# Check the status of the solution
if termination_status(model) == MOI.OPTIMAL
    println("Optimal solution found")
    println("Objective value: ", objective_value(model))
    
else
    println("No optimal solution found")
end

for slot in slots
    total_cubes = 0
    for cube in cubes
        if round(value(cs[cube, slot])) == 1
            println("slot $slot Cube $cube")
            total = 0
            for player in players
                if round(value(pcs[player, cube, slot])) == 1
                    println("Player $player")
                    total += 1
                end
            end
            @assert total == 8
            total_cubes += 1
        end
    end
    @assert total_cubes == length(players) / 8
end
