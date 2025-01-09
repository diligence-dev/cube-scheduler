using HTTP

function generate_mailto_link(email, name, cube1, cube2, cube3, top8_cube)
    subject = "Deine Cube Open Potsdam Cubes"
    body = """
    Hallo $name,

    endlich ist es soweit! Hier die Cubes, die du auf dem Cube Open Potsdam draften wirst:
    18.1.2025 Samstag Vormittag: $cube1
    18.1.2025 Samstag Nachmittag: $cube2
    19.1.2025 Sonntag Vormittag: $cube3

    Wer nach den 9 Runden unter den Top 8 ist spielt folgenden Cube um den Turniersieg:
    19.1.2025 Sonntag Nachmittag: $top8_cube

    Wir freuen uns dich auf dem Cube Open zu treffen!

    Liebe Grüße,
    dein Cube Open Orga Team
    """
    mailto = "mailto:$email?subject=$(HTTP.escapeuri(subject))&body=$(HTTP.escapeuri(body))"
    return "<a href=\"$mailto\">Send email to $name</a><br>"
end

function write_mailto_html(recipients, top8_cube)
    html_content = "<html><body>"
    for (email, name, cube1, cube2, cube3) in recipients
        html_content *= generate_mailto_link(email, name, cube1, cube2, cube3, top8_cube)
    end
    html_content *= "</body></html>"

    # Write the HTML content to a file
    open("mails.html", "w") do file
        write(file, html_content)
    end

    println("HTML file with mailto links generated: mails.html")
end
