#!/bin/bash

# Get the directory and base name of the script
script_dir=$(dirname "$0")
script_name=$(basename "$0")

# Remove the extension from the file name
bot_name=${script_name%.*}

run_cmd=$script_dir/$bot_name
echo "running "$run_cmd
$run_cmd