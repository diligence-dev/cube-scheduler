using HTTP
using DataFrames
using CSV

function generate_mailto_link(email, name, cube1, cube2, cube3, top8_cube)
    cubes = CSV.read("cubes.csv", DataFrame)
    link1 = cubes[cube1 .== cubes[!, 1], 2][1]
    link2 = cubes[cube2 .== cubes[!, 1], 2][1]
    link3 = cubes[cube3 .== cubes[!, 1], 2][1]
    link_top8 = cubes[top8_cube .== cubes[!, 1], 2][1]
    subject = "Deine Cubes - Cube Open Potsdam"
    body = """
    Hallo $name,

    endlich ist es soweit! Hier sind die Cubes, die du auf dem Cube Open Potsdam draften wirst:
    18.1.2025 Samstag 10 Uhr: $cube1 - $link1
    18.1.2025 Samstag 15 Uhr: $cube2 - $link2
    19.1.2025 Sonntag 10 Uhr: $cube3 - $link3

    Wer nach den 9 Runden unter den Top 8 ist spielt folgenden Cube um den Turniersieg:
    19.1.2025 Sonntag 15 Uhr: $top8_cube - $link_top8

    Tipp: Auf Cubecobra kannst du beliebige Cubes gegen Bots draften - einfach auf Playtest (oben rechts neben Overview und List) klicken und einen Draft starten.

    Wir freuen uns schon sehr, dich auf dem Cube Open zu treffen!

    Liebe Grüße,
    dein Cube Open Orga Team
    """
    mailto = "mailto:$email?subject=$(HTTP.escapeuri(subject))&body=$(HTTP.escapeuri(body))"
    return "<a href=\"$mailto\">Send email to $name</a><br>"
end

function write_mailto_html(slots, cubes, players, cube_names, player_mails, pcs, top8_cube, player_names)
    html_content = "<html><body>"
    for p in players
        player_cubes = []
        for s in slots
            for c in cubes
                if round(value(pcs[p, c, s])) == 1
                    push!(player_cubes, cube_names[c])
                end
            end
        end

        player_name = split(player_names[p])[1]
        player_name = uppercase(player_name[1]) * player_name[2:end]
        html_content *= generate_mailto_link(player_mails[p], player_name,
                                             player_cubes[1], player_cubes[2], player_cubes[3], top8_cube)
    end
    html_content *= "</body></html>"

    # Write the HTML content to a file
    open("mails.html", "w") do file
        write(file, html_content)
    end

    println("HTML file with mailto links generated: mails.html")
end
