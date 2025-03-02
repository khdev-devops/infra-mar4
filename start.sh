#!/bin/bash

# Avbryt scriptet om ett kommando misslyckas
set -e

if [ ! -d "venv" ]; then
    echo "📦 Skapar en virtuell Python-miljö..."
    python3 -m venv venv
fi

echo "✅ Aktiverar den virtuella miljön"
source venv/bin/activate

# TODO: saknas det dependencies i python?
#   tips: https://www.geeksforgeeks.org/how-to-install-python-packages-with-requirements-txt/

# TODO: saknas det värden på miljövariabler (environment variables)?
#   tips: kolla .env.template

echo "🚀 Startar Flask-servern..."
python3 app.py