function print_solution(slots, cubes, players, cube_names, player_mails, zero_players, pcs, print_players = true)
    unique_cubes = Set()
    for slot in slots
        println("\nSlot $slot -------------------------------")
        for cube in cubes
            if round(value(zero_players[cube, slot])) == 1
                continue
            end
            push!(unique_cubes, cube_names[cube])
            println(cube_names[cube])
            if print_players
                n_players = 0
                for player in players
                    if round(value(pcs[player, cube, slot])) == 1
                        println(player_mails[player])
                        n_players += 1
                    end
                end
                println("n_players = $n_players\n")
            end
        end
    end
    println("\nnumber of unique cubes: ", length(unique_cubes))
end

function print_cube_scores(cubes, players, score, cube_names)
    cube_scores = Dict(cube => 0 for cube in cubes)

    for p in players
        for c in cubes
            cube_scores[c] += score[p, c]
        end
    end
    sorted_cube_scores = sort(collect(cube_scores), by = x -> -x[2])
    for (cube, score) in sorted_cube_scores
        println(cube_names[cube], ": ", score)
    end
end

function print_wish_counts(preferences, pid, slots, cubes, pcs, cube_names)
    println("rank_to_score: ", rank_to_score)
    wish_counts = zeros(Int, 6)

    for i in 1:nrow(preferences)
        player_mail = preferences[i, 2]
        p = pid(player_mail)
        for s in slots
            for c in cubes
                if value(pcs[p, c, s]) > 0.5
                    wish_granted = false
                    for w in 1:5
                        if !ismissing(preferences[i, w + 2]) && preferences[i, w + 2] == cube_names[c]
                            wish_counts[w] += 1
                            wish_granted = true
                        end
                    end
                    if !wish_granted && !ismissing(preferences[i, 7])
                        println(player_mail, " got ", cube_names[c], " but did not want it")
                        wish_counts[6] += 1
                    end
                end
            end
        end
    end

    println("wish_counts: ", wish_counts)
end
