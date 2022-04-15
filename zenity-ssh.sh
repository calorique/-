#!/bin/bash

# Script: zenity-ssh.sh
# Author: Lambert Z.Y. Li
# Date: 2021-09-01 10:35:00 AM

#REMOTE_HOST_FILE="${HOME}/.ssh/ssh_hist.list"
REMOTE_HOST_FILE="/home/local/etc/ssh_history"
#SMART_SSH='/home/local/bin/smart-ssh.sh'
KNOWN_HOSTS="${HOME}/.ssh/known_hosts"

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

function check_cmd() {
	[[ $# -eq 1 ]] || die "\"$*\" is more than 1 param!"
	command -v $1 >/dev/null || die "Command \"$1\" was not found in system!"
}

function check_root_privilege()
{
	# Compitable to sudo environment.
	[[ "X${USER}" == "Xroot" ]] || die "Current user is not root!"
	# Without practice
	#[[ $(id -u) -eq 0 ]] || die "Only user root is allowed to run this script!"
}


function ssh_one_string()
{
	local INSTR
	INSTR=$(zenity --width=600 --entry \
	--title "Remote Desktop" \
	--text "Connection params:" \
	--entry-text "Hostname:root:123456:Desciption")

	[[ -z ${INSTR} ]] && die "Null param input!"

	local HOST
	HOST=$(echo "${INSTR}" | awk -F: '{print $1}')
	if [[ -z ${HOST} ]]
	then
		warn "Without host."
	else
		local USER
		USER=$(echo "${INSTR}" | awk -F: '{print $2}')
		if [[ -z ${USER} ]]
		then
			warn "Without user."
		else
			local PASSWD
			PASSWD=$(echo "${INSTR}" | awk -F: '{print $3}')
			if [[ -z ${PASSWD} ]]
			then
				warn "Without password."
			fi
		fi
	fi

	[[ -z ${USER}   ]] || OPTION_USER="-u ${USER}"
	[[ -z ${PASSWD} ]] || OPTION_PASSWD="-p ${PASSWD}"

	if ping -c 2 "${HOST}"
	then
		echo "${INSTR}" >>"${REMOTE_HOST_FILE}"
		do_ssh "${HOST}" "${USER}" #"${PASSWD}"
		#"${SMART_SSH}" "${USER}@${HOST}"
	else
		zenity --width=180 --error --text="Host ${HOST} is unreachable!"
		exit 2
	fi
}


function ssh_one_by_one()
{
	local INSTR
	INSTR=$(zenity --forms --title="Remote Desktop" \
		--text="With params:" \
		--separator="," \
		--add-entry="host" \
		--add-entry="user" \
		--add-password="password" \
		--add-entry="desciption")

	[[ -z ${INSTR} ]] && die "Null param input!"

	local HOST
	HOST=$(echo "${INSTR}" | awk -F',' '{print $1}')

	local USER
	USER=$(echo "${INSTR}" | awk -F',' '{print $2}')
	
	local PASSWD
	PASSWD=$(echo "${INSTR}" | awk -F',' '{print $3}')

	local DESCRIPT
	DESCRIPT=$(echo "${INSTR}" | awk -F',' '{print $3}')

	if [[ -z ${HOST} ]]
	then
		zenity --width=250 --error --text="Host address is either invalid or null!"
		exit 1
	fi

	if ! ping -c 1 "${HOST}"
	then
		zenity --width=180 --error --text="Host ${HOST} is unreachable!"
		exit 2
	fi

	[[ -z ${USER} ]] || OPTION_USER="-u ${USER}"
	[[ -z ${PASSWD} ]] || OPTION_PASSWD="-p ${PASSWD}"

	if ping -c 1 "${HOST}"
	then
		do_ssh "${HOST}" "${USER}" #"${PASSWD}"
	else
		zenity --width=180 --error --text="Host ${HOST} is unreachable!"
		exit 2
	fi
}


function new_session_with_zenity()
{
	local INSTR
	INSTR=$(zenity --forms --title="Remote Desktop" \
		--text="With params:" \
		--separator="," \
		--add-entry="host" \
		--add-entry="user" \
		--add-password="password" \
		--add-entry="descript")

	[[ -z ${INSTR} ]] && die "Null param input!"

	local HOST
	HOST=$(echo "${INSTR}" | awk -F',' '{print $1}')
	local USER
	USER=$(echo "${INSTR}" | awk -F',' '{print $2}')
	local PASSWD
	PASSWD=$(echo "${INSTR}" | awk -F',' '{print $3}')
	local DESC
	DESC=$(echo "${INSTR}" | awk -F',' '{print $4}')

	[[ -z ${HOST} ]] || {
		#zenity --width=250 --error --text="Host address is either invalid or null!"
		echo "Host name is absent."
		new_session_with_zenity "$@"
	}

	[[ -z ${USER} ]] || {
		#zenity --width=250 --error --text="User name is either invalid or null!"
		echo "User name is absent."
		new_session_with_zenity "$@"
	}

	echo "${HOST}:${DOMAIN}:${USER}:${PASSWD}:${DESC}" | tee -a "${REMOTE_HOST_FILE}" \
		|| die "Failed to create new session!"

	do_ssh "${HOST}" "${USER}" "${PASSWD}" "${DESC}" || new_session_with_zenity "$@"
}


function default_edit() {
	command -v vi >/dev/null && EDITOR=vi
	command -v vim >/dev/null && EDITOR=vim
	command -v nvim >/dev/null && EDITOR=nvim
	command -v gedit >/dev/null && EDITOR=gedit
	#command -v subl && EDITOR=subl

	#echo "EDITOR=${EDITOR}"
	#echo "$@"

	"${EDITOR}" "$@"
}


function zenity_edit() {
	OPTION=$(zenity --width=250 --height=210 \
		--list --title "Zenity Select Editor Dialog" \
		--column "" \
		--hide-header \
		"sublime_text" \
		"gedit" \
		"neovim" \
		"[Quit]")

	EDITOR=vim
	case ${OPTION} in
		"sublime_text")
			EDITOR=subl;;
		"gedit")
			EDITOR=gedit;;
		"neovim")
			EDITOR=nvim;;
		"[Quit]")
			exit 0;;
	esac

	command -v "${EDITOR}" >/dev/null || {
		zenity --warning --width=200 --text "${EDITOR} was not found, try other editor!"
		zenity_edit "$@"
	}

	"${EDITOR}" "$@"
}


function validate_param()
{
	[[ 4 -eq "$(echo "$@" | awk -F: '{print NF}')" ]] || die "4 params are required!"
}


function ssh_connect()
{
	[[ -z "$1" ]] && die "ssh_connect(): Null string input."

	HOST="$(echo "$1" | awk -F: '{print $1}')"
	[[ -z "${HOST}" ]] && die "HOST is Null!"

	USER="$(echo "$1" | awk -F: '{print $2}')"
	[[ -z "${USER}" ]] && die "USER is Null!"

	PASSWD="$(echo "$1" | awk -F: '{print $4}')"
	[[ -z "${PASSWD}" ]] && die "PASSWD is Null!"

	if : #ping -c 1 "${HOST}"
	then
		do_ssh "${HOST}" "${USER}" #"${PASSWD}"
	else
		zenity --width=180 --error --text="Host ${HOST} is unreachable!"
		exit 2
	fi
}

function clear_known_host()
{
	HOSTNAME=$1

	[[ -z "${KNOWN_HOSTS}" ]] || return 0
	[[ -f "${KNOWN_HOSTS}" ]] || return 0

	XHASH="$(grep "${HOSTNAME}" "${KNOWN_HOSTS}" | awk '{print $3}' | head -1)"
	[[ -z "${XHASH}" ]] && return 0

	TMP_HOSTS="$(mktemp --suffix=_known_hosts)"
	grep -v "${XHASH}" "${KNOWN_HOSTS}" >"${TMP_HOSTS}" \
		&& cat "${TMP_HOSTS}" >"${KNOWN_HOSTS}" \
		&& rm -f "${TMP_HOSTS}"
}

function do_ssh() {
	HOST="$1"
	USER="$2"
	#PSWD="$3"

	#echo "USER=${USER}"
	#echo "HOST=${HOST}"

	[[ "X${HOST}" == "X" ]] && {
		echo "Host name is absent."
		return 255
	}

	[[ "X${USER}" == "X" ]] && {
		echo "Username is absent."
		return 255
	}

	expect -c "set timeout 30;
spawn ssh ${USER}@${HOST}
expect {
	*yes/no?* {
		send yes\r; exp_continue;
	}
	*Y/n?* {
		send y\r; exp_continue;
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
	*truenas%* {
		exit 100;
	}
	*Now\ try\ logging\ into\ the\ machine* {
		exit 100;
	}
	*:~\$* {
		exit 100;
	}
	*\ ~\ #* {
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
		ssh -Y ${USER}@${HOST}
	elif [[ ${RET} -eq 102 ]]
	then
		echo "Test failed! Update password..."
		ssh-copy-id ${USER}@${HOST}
		"$0" "$@"
	elif [[ ${RET} -eq 103 ]]
	then
		echo "Test failed! Update new key..."
		#ssh-keygen -R ${HOST}
		clear_known_host "${HOST}"
		expect -c "set timeout 30;
spawn ssh-copy-id ${USER}@${HOST}
expect {
	*Warning:* {exp_continue;}
	*INFO:* {exp_continue;}
	*yes/no?* {send yes\r;exp_continue;}
	*password:* {interact;}
	*${USER}@${HOST}\'s password:* {interact;}
	eof {exit 0;}
}";
	"$0" "$@"
	fi
}

# Main Process
check_cmd ssh
check_cmd zenity
#check_exec "${SMART_SSH}"

[[ -f "${REMOTE_HOST_FILE}" ]] || {
	touch "${REMOTE_HOST_FILE}" || die "Failed to create ${REMOTE_HOST_FILE}!"
}

[[ $# -ge 2 ]] && {
	local HOST="$1"
	local USER="$2"
	local PSWD="$3"

	echo "HOST=$1,USER=$2,PSWD=$3"
	do_ssh "$@"

	exit 0
}

unset https_proxy

# Debug:
#cat "${REMOTE_HOST_FILE}" | while read X; do
#	echo "FALSE \"${X}\""
#done

#		--column "Host:Domain:User:Passwd" \
#		--column "--------------------------------------------------" \
OPTN=$(zenity --width=550 --height=600 \
		--list --title "Zenity SSH Dialog" \
		--column "" \
		--hide-header \
		$(cat "${REMOTE_HOST_FILE}" | grep -Ev '^#|^$' | while read X; do
			echo "${X}"
		done
		) \
		"[Create new remote connection...]" \
		"[Edit connection list...]" \
		"[Edit this menu...]" \
)

#zenity --width=500 --info --text="Confirm selection: ${OPTN}"

case ${OPTN} in
	"[Create new remote connection...]")
		#ssh_one_string;;
		#ssh_one_by_one;;
		new_session_with_zenity;;
	"[Edit connection list...]")
		default_edit "${REMOTE_HOST_FILE}";;
	"[Edit this menu...]")
		default_edit "$(readlink -f $0)";;
	*)
		#zenity --width=120 --error --text="Invalid option!";;
		validate_param "${OPTN}"
		ssh_connect "${OPTN}"
		;;
esac

# xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}"
