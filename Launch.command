#!/bin/zsh
set -eu
project_dir="${0:A:h}"
godot_bin="/Applications/Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$godot_bin" ]]; then
  print "Please open project.godot with Godot 4.5 or later."
  exit 1
fi
mkdir -p "$project_dir/evidence"
exec "$godot_bin" --path "$project_dir" --log-file "$project_dir/evidence/play.log" "$@"
