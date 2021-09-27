#!/bin/bash

function usage(){
	echo "Usage: $0 {FILE}"
}

function die(){
	echo "$*"
	exit 255
}

# Main Process
[[ $# -eq 1 ]] || die "$(usage)"
[[ -f "$1" ]] || die "Error: $1 is unaccessible."

grep -v $'^[\t ]*#\|^$' "$1"

