#!/bin/bash

# Get the directory and base name of the script
script_dir=$(dirname "$0")
script_name=$(basename "$0")

# create ENVs if provided
if [ -z "$1" ]
    then
        echo "No argument supplied"
    else
        export SERVER_URL=$1
fi

if [ -z "$2" ]
    then
        echo "No argument supplied"
    else
        export SERVER_SECRET=$2
fi

# Remove the extension from the file name
bot_name=${script_name%.*}

$script_dir/$bot_name