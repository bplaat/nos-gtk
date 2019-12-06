#!/bin/bash
APP_NAME="ml.bastiaan.nos"
clear
if valac --thread --pkg gtk+-3.0 --pkg libsoup-2.4 --pkg json-glib-1.0 $(find src -name "*.vala") -o ~/.local/bin/$APP_NAME; then
    cp data/$APP_NAME.desktop ~/.local/share/applications
    ml.bastiaan.nos
fi
