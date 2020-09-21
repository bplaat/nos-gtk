name="nl.plaatsoft.nos"
if valac --pkg gtk+-3.0 --pkg libsoup-2.4 --pkg json-glib-1.0 $(find src -name "*.vala") -o ~/.local/bin/$name; then
    cp data/$name.desktop ~/.local/share/applications
    $name
fi
