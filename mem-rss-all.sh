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

RSS=0

for X in /proc/* #$(ls /proc/ | grep "^[0-9]")
do
	if [[ -f "${X}/statm" ]]
	then
		TMP=$(awk '{print $2}' "${X}/statm")
		RSS=$((RSS + TMP))
	fi
done

if [[ -x /home/local/bin/kmgtpe ]]
then
	note "$(/home/local/bin/kmgtpe $((RSS * 4 * 1024)))"
else
	info "$((RSS * 4))KB"
fi
