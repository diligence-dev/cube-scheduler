using CSV
using DataFrames
using JuMP
using SCIP

include("output.jl")
include("get_score.jl")

rank_to_score = [20, 17, 16, 12, 11]
# rank_to_score = [5, 4, 3, 2, 1] # wish_counts: [34, 30, 27, 11, 5, 2]
# rank_to_score = [10, 9, 7, 4, 2]
# rank_to_score = [10, 8, 6, 4, 2]

top8_cube = "???"

player_mails = lowercase.(readlines("mails"))
if length(player_mails) % 2 == 1
    push!(player_mails, "bye")
end
@assert player_mails == unique(player_mails)

preferences = CSV.read("preferences.csv", DataFrame)
preferences[!, 2] = lowercase.(preferences[!, 2])
duplicates = filter(x -> count(y -> y == x, preferences[!, 2]) > 1, unique(preferences[!, 2]))
if length(duplicates) > 0
    println("The following mails are duplicated:")
    println.(duplicates)
    throw("Duplicated mails")
end

not_registered = filter(row -> !(row[2] in player_mails), preferences)[!, 2]
if length(not_registered) > 0
    println("The following mails are not registered:")
    println.(not_registered)
    throw("Not registered")
end

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
casuals = [pid(mail) for mail in lowercase.(readlines("casual"))]
for casual in casuals
    @assert casual in players
end
competitives = setdiff(players, casuals)

slots = 1:3
cubes = 1:length(cube_names)

# Define the parameters (=scores)
score = get_score(preferences, player_mails, cubes, cid, rank_to_score)

# Create the model
model = Model(SCIP.Optimizer)

# Define the variables
@variable(model, pcs[p in players, c in cubes, s in slots], Bin)
@variable(model, zero_players[c in cubes, s in slots], Bin)
# @variable(model, six_players[c in cubes, s in slots], Bin)
@variable(model, eight_players[c in cubes, s in slots], Bin)
# @variable(model, ten_players[c in cubes, s in slots], Bin)
@variable(model, twelve_casuals[c in cubes, s in slots], Bin)

# Define the constraints
# each cube is played by 0, 6, 8 or 10 players
# @constraint(model, [c in cubes, s in slots], zero_players[c, s] + six_players[c, s] + eight_players[c, s] + ten_players[c, s] == 1)
@constraint(model, [c in cubes, s in slots], zero_players[c, s] + eight_players[c, s] + twelve_casuals[c, s] == 1)
# @constraint(model, [c in cubes, s in slots], sum(pcs[p, c, s] for p in players) == 0 * zero_players[c, s] + 6 * six_players[c, s] + 8 * eight_players[c, s] + 10 * ten_players[c, s])
@constraint(model, [c in cubes, s in slots], sum(pcs[p, c, s] for p in competitives) == 0 * zero_players[c, s] + 8 * eight_players[c, s])
@constraint(model, [c in cubes, s in slots], sum(pcs[p, c, s] for p in casuals) == 0 * zero_players[c, s] + 12 * twelve_casuals[c, s])

# each player plays exactly one cube in each slot
@constraint(model, [p in players, s in slots], sum(pcs[p, c, s] for c in cubes) == 1)

# a player cannot play a cube twice
@constraint(model, [p in players, c in cubes], sum(pcs[p, c, s] for s in slots) <= 1)

# prevent assigning to the cube reserved for top 8
@constraint(model, [p in players, s in slots], pcs[p, cid(top8_cube), s] == 0)

# prevent two players from ever drafting at the same table
# @constraint(model, [c in cubes, s in slots], pcs[special_player_1, c, s] + pcs[special_player_2, c, s] <= 1)

# Define the objective
@objective(model, Max,
           sum(pcs[p, c, s] * score[p, c] for p in players, c in cubes, s in slots))
        #    - 500 * sum(ten_players[c, s] for c in cubes, s in slots)
        #    - 1000 * sum(six_players[c, s] for c in cubes, s in slots))

# accept solutions that are 95% optimal
# set_optimizer_attribute(model, "limits/gap", 0.05) # TODO comment out for final solution

optimize!(model)
if termination_status(model) != MOI.OPTIMAL
    throw("No solution found")
end

# print_solution(slots, cubes, players, cube_names, player_mails, zero_players, pcs, model)

print_wish_counts(preferences, pid, slots, cubes, pcs, cube_names, competitives)
