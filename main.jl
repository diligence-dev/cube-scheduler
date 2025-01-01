using CSV
using DataFrames
using JuMP
using SCIP

rank_to_score = [100, 70, 50, 10, 5]

# read in preferences.csv as dataframe
preferences = CSV.read("preferences.csv", DataFrame)
preferences = preferences[1:16, :]


player_mails = readlines("mails")[1:48]

cube_names = filter(.!ismissing, unique([preferences[!, 3];
                     preferences[!, 4];
                     preferences[!, 5];
                     preferences[!, 6];
                     preferences[!, 7]]))

function pid(player_mail)
    return findfirst(player_mail .== player_mails)
end

function cid(cube_name)
    return findfirst(cube_name .== cube_names)
end

# TODO preferences JOS = HEIKE

# Define the sets
players = 1:length(player_mails)
slots = 1:3
cubes = 1:length(cube_names)

# Define the parameters (=scores)
score = zeros(length(players), length(cubes))

for pmail in preferences[!, 2]
    p = pid(pmail)
    if isnothing(p)
        println("mail $pmail is not in list")
        continue
    end
    picks = [preferences[preferences[!, 2] .== player_mails[p], i][1] for i in 3:7]
    unique!(picks)
    filter!(x -> !ismissing(x), picks)

    for i in eachindex(rank_to_score)
        if i > length(picks)
            for cube in setdiff(cubes, cid.(picks))
                score[p, cube] = rank_to_score[i]
            end
            break
        end
        score[p, cid(picks[i])] = rank_to_score[i]
    end
end

# Create the model
model = Model(SCIP.Optimizer)

# Define the variables
@variable(model, cs[c in cubes, s in slots], Bin)
@variable(model, pcs[p in players, c in cubes, s in slots], Bin)

# Define the constraints
@constraint(model, [c in cubes, s in slots], 8 * cs[c, s] == sum(pcs[p, c, s] for p in players))
@constraint(model, [p in players, s in slots], sum(pcs[p, c, s] for c in cubes) == 1)
@constraint(model, [p in players, c in cubes], sum(pcs[p, c, s] for s in slots) <= 1)

# TODO prevent Heike and Jos from playing at the same table
# TODO check how much worse total score is with this constraint
# @constraint(model, [c in cubes, s in slots], pcs[HEIKE, c, s] + pcs[JOS, c, s] <= 1)

# Define the objective
@objective(model, Max, sum(pcs[p, c, s] * score[p, c] for p in players, c in cubes, s in slots))

# Solve the model
optimize!(model)

# Print solution
for slot in slots
    total_cubes = 0
    for cube in cubes
        if round(value(cs[cube, slot])) == 1
            println("\nslot $slot Cube ", cube_names[cube])
            total = 0
            for player in players
                if round(value(pcs[player, cube, slot])) == 1
                    println("Player ", player_mails[player])
                    total += 1
                end
            end
            @assert total == 8
            total_cubes += 1
        end
    end
    @assert total_cubes == length(players) / 8
end

if termination_status(model) == MOI.OPTIMAL
    println("\nOptimal solution found, Objective value: ", objective_value(model))
else
    println("No optimal solution found")
end
