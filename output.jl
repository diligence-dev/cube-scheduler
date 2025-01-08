function print_solution(slots, cubes, players, cube_names, player_mails, zero_players, pcs, model)
    if termination_status(model) != MOI.OPTIMAL
        throw("No optimal solution found")
    end

    for slot in slots
        println("\nSlot $slot --------------")
        total_cubes = 0
        for cube in cubes
            if round(value(zero_players[cube, slot])) == 1
                continue
            end
            println("\n", cube_names[cube])
            total = 0
            for player in players
                if round(value(pcs[player, cube, slot])) == 1
                    println("Player ", player_mails[player])
                    total += 1
                end
            end
            @assert total in [6, 8, 10, 12]
            println("total = $total")
            total_cubes += 1
        end
    end

    println("\nObjective value: ", objective_value(model))
    # println("Objective value per player (max possible: ",
    #         sum(rank_to_score[1:length(slots)]), "): ",
    #         objective_value(model) / nrow(preferences))
    # println("Objective value relative: ",
    #         objective_value(model) / nrow(preferences) / sum(rank_to_score[1:length(slots)]))
end
