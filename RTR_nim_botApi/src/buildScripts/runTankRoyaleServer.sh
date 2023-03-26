#!/bin/bash

print_usage() {
  printf "Usage: [-j jarFileFullPath] [-b botSecret] [-c controllerSecret] [-p port]"
}

while getopts 'j:b:c:p:' flag; do
  case "${flag}" in
    j) jarFile="${OPTARG}" ;;
    b) botSecret="${OPTARG}" ;;
    c) controllerSecret="${OPTARG}" ;;
    p) port="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

echo "Running Tank Royale Server with the following parameters:"
# echo "java -jar $jarFile --botSecrets=$botSecret --controllerSecrets=$controllerSecret --port=$port --enable-initial-position"
nohup java -jar $jarFile --botSecrets=$botSecret --controllerSecrets=$controllerSecret --port=$port --enable-initial-position &
echo "$!" > /tmp/tankRoyaleServer_$port.pid