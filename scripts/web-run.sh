#!/bin/sh
# Run the html version of the game on port 8000

python3 -m http.server 8000 --directory build/web
