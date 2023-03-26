#!/bin/bash

# Get the directory and base name of the script
script_dir=$(dirname "$0")
script_name=$(basename "$0")

# create ENVs if provided
print_usage() {
  printf "Usage: [-u IP:PORT] [-s BOT-SECRET]"
}

while getopts 'u:s:' flag; do
  case "${flag}" in
    u) export SERVER_URL="ws://${OPTARG}" ;;
    s) export SERVER_SECRET="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

echo "SERVER_URL:$SERVER_URL"
echo "SERVER SECRET:$SERVER_SECRET"

# Remove the extension from the file name
bot_name=${script_name%.*}

$script_dir/$bot_name