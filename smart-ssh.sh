#!/bin/bash

################################################################
# Script: install-from-iso.sh
# Author: Lambert Z.Y. Li
# Date: 2020-8-07 11:03 AM
# Purpose: install software from local ISO image.
################################################################

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

function check_dir()
{
	if [[ $# -gt 0 ]]
	then
		for X in "$@"
		do
			[[ -d ${X} ]] || die "${X} was not found!"
		done
	else
		die "check_dir(): Null param!"
	fi
}

function check_file()
{
	if [[ $# -gt 0 ]]
	then
		for X in "$@"
		do
			[[ -f ${X} ]] || die "${X} was not found!"
		done
	else
		die "check_file(): Null param!"
	fi
}

function check_exec()
{
	if [[ $# -gt 0 ]]
	then
		for X in "$@"
		do
			[[ -f ${X} ]] || die "${X} was not found!"
			[[ -x ${X} ]] || die "${X} was not executable!"
		done
	else
		die "check_exec(): Null param!"
	fi
}

function usage()
{
	echo "Usage: $0 username@hostname"
}

# Main process...
[[ $# -eq 1 ]] || die "$(usage)"

USER="$(echo $1 | awk -F@ '{print $1}')"
HOST="$(echo $1 | awk -F@ '{print $2}')"

#echo "USER=${USER}"
#echo "HOST=${HOST}"

[[ "X${USER}" == "X" ]] && {
	echo "Username is absent."
	usage
	exit 255
}

[[ "X${HOST}" == "X" ]] && {
	echo "Host name is absent."
	usage
	exit 255
}

[[ "X${USERHOST}" == "X${USER}" ]] && usage
[[ "X${USERHOST}" == "X${HOST}" ]] && usage

expect -c "set timeout 30;
spawn ssh ${USER}@${HOST}
expect {
	*yes/no?* {
		send yes\r; exp_continue;
	}
	*password:* {
		exit 102;
	}
	*REMOTE\ HOST\ IDENTIFICATION\ HAS\ CHANGED* { 
		exit 103;
	}
	** {
		exit 100;
	}
	*]\$* {
		exit 100;
	}
	*#\ * {
		exit 100;
	}
	eof {
		exit 0;
	}
}";

RET=$?

if [[ ${RET} -eq 100 ]]
then
	echo "Test OK! Reconnect..."
	ssh ${USER}@${HOST}
elif [[ ${RET} -eq 102 ]]
then
	echo "Test failed! Update password..."
	ssh-copy-id ${USER}@${HOST}
	"$0" "$@"
elif [[ ${RET} -eq 103 ]]
then
	echo "Test failed! Update new key..."
	ssh-keygen -R ${HOST}
	expect -c "set timeout 30;
spawn ssh-copy-id ${USER}@${HOST}
expect {
	*yes/no?* {send yes\r; exp_continue;}
	*password:* {interact;}
	eof {exit 0;}
}";
	"$0" "$@"
fi



