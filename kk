#!/bin/bash

function die()
{
	echo -e "\033[31m$*\033[0m"
	exit 255
}

function error()
{
	echo -e "\033[31m$*\033[0m"
}

function warn()
{
	echo -e "\033[33m$*\033[0m"
}

function note()
{
	echo -e "\033[36m$*\033[0m"
}

function info()
{
	echo -e "\033[32m$*\033[0m"
}

usage() {
	echo "Usage: $0 {keyword}"
}

succeed() {
	warn "$*"
	exit 0
}

# Main Process Start Here.
[ $# -eq 1 ] || die "$(usage)"
K=$1

while true
do
	mapfile -t PIDLIST < <(pgrep "${K}")
	[[ ${#PIDLIST[@]} -eq 0 ]] && succeed "All clear."
	echo -e "Found process\033[36m ${PIDLIST[*]}\033[0m still running, trying to..."

	for X in "${PIDLIST[@]}"
	do
		info "kill -9 ${X}"
		kill -9 "${X}"
	done

	sleep 0.5
done

