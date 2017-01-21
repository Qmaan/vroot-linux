#!/bin/bash

if [ $# -ge 1 ]; then

node="$1"

foldername=$(date +%Y-%m-%d-%H-%M-%S)

mkdir -p collectedLogs/"$foldername-$node"

hcp $node:/etc/conpot.log ./collectedLogs/"$foldername-$node"/

fi
