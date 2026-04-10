#!/bin/sh
# Print this help text

SCRIPTS_DIR="$(dirname "$0")"

for file in "$SCRIPTS_DIR"/*.sh; do
    name="$(basename "$file")"
    help_text="$(sed -n '2p' "$file")"

    printf "%-20s %s\n" "$name" "$help_text"
done
