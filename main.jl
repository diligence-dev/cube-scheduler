using CSV
using DataFrames
using JuMP
using SCIP

rank_to_score = [100, 70, 50, 10, 5]
special_player_1 = 26
special_player_2 = 27

player_mails = lowercase.(readlines("mails"))
@assert player_mails[special_player_1] == player_mails[special_player_2]
player_mails[special_player_1] = "special_player_1"
@assert player_mails == unique(player_mails)

preferences = CSV.read("preferences.csv", DataFrame)
preferences[!, 2] = lowercase.(preferences[!, 2])

preferences = preferences[[1:nrow(preferences); [findfirst(preferences[!, 2] .== player_mails[special_player_2])]], :]
preferences[nrow(preferences), 2] = "special_player_1"
@assert preferences[!, 2] == unique(preferences[!, 2])

println("The following mails are not registered:")
println.(filter(row -> !(row[2] in player_mails), preferences)[!, 2])

filter!(row -> row[2] in player_mails, preferences)

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

# Define the sets
players = 1:length(player_mails)
slots = 1:3
cubes = 1:length(cube_names)

# Define the parameters (=scores)
score = zeros(length(players), length(cubes))

for pmail in preferences[!, 2]
    p = pid(pmail)
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
@variable(model, pcs[p in players, c in cubes, s in slots], Bin)
@variable(model, zero_players[c in cubes, s in slots], Bin)
@variable(model, six_players[c in cubes, s in slots], Bin)
@variable(model, eight_players[c in cubes, s in slots], Bin)
@variable(model, ten_players[c in cubes, s in slots], Bin)

# Define the constraints
@constraint(model, [c in cubes, s in slots], zero_players[c, s] + six_players[c, s] + eight_players[c, s] + ten_players[c, s] == 1)
@constraint(model, [c in cubes, s in slots], sum(pcs[p, c, s] for p in players) == 0 * zero_players[c, s] + 6 * six_players[c, s] + 8 * eight_players[c, s] + 10 * ten_players[c, s])
@constraint(model, [p in players, s in slots], sum(pcs[p, c, s] for c in cubes) == 1)
@constraint(model, [p in players, c in cubes], sum(pcs[p, c, s] for s in slots) <= 1)

# prevent two players from ever drafting at the same table
# TODO check how much worse total score is with this constraint
@constraint(model, [c in cubes, s in slots], pcs[special_player_1, c, s] + pcs[special_player_2, c, s] <= 1)


# Define the objective
@objective(model, Max,
           sum(pcs[p, c, s] * score[p, c] for p in players, c in cubes, s in slots)
           - 500 * sum(ten_players[c, s] for c in cubes, s in slots)
           - 1000 * sum(six_players[c, s] for c in cubes, s in slots))

# Solve the model
optimize!(model)

# Print solution
for slot in slots
    total_cubes = 0
    for cube in cubes
        if round(value(zero_players[cube, slot])) == 1
            continue
        end
        println("\nslot $slot Cube ", cube_names[cube])
        total = 0
        for player in players
            if round(value(pcs[player, cube, slot])) == 1
                println("Player ", player_mails[player])
                total += 1
            end
        end
        @assert total in [6, 8, 10]
        println("total = $total")
        total_cubes += 1
    end
end

if termination_status(model) != MOI.OPTIMAL
    throw("No optimal solution found")
end
println("\nObjective value: ", objective_value(model))
println("Objective value per player (max possible: ",
        sum(rank_to_score[1:length(slots)]), "): ",
        objective_value(model) / nrow(preferences))
println("Objective value relative: ",
        objective_value(model) / nrow(preferences) / sum(rank_to_score[1:length(slots)]))
