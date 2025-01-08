function get_score(preferences::DataFrame, player_mails::Vector{String}, cubes::UnitRange{Int}, cid, rank_to_score::Vector{Int})
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
    return score
end
