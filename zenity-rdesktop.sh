#!/bin/bash
################################################################
# Script: autoRun.sh
# Author: Hankai
# Date: 2018-04-26 09:22:12 AM
# Purpose: This script is used to config Centos7.3
################################################################

################################################################
################ Define some functions here ##################
################################################################
REMOTE_HOST_FILE="/home/local/etc/rdp_history"

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


function check_root_privilege()
{
	# Compitable to sudo environment.
	[[ "X${USER}" == "Xroot" ]] || die "Current user is not root!"
	# Without practice
	#[[ $(id -u) -eq 0 ]] || die "Only user root is allowed to run this script!"
}


function do_xfreerdp() {
	#echo xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /usb:id,dev:046a:00b4 /w:1440 /h:900 /v:"$1" /u:"$2" /p:"$3"
	#xfreerdp /sec:nla +sec-ext /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +themes +decorations +menu-anims +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4"
	# Wayland
	#echo wlfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4"
	#wlfreerdp -themes /disp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4"
	
	# Xorg
	echo xfreerdp /sec:nla /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +themes +decorations +menu-anims +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4" >/tmp/xfreerdp.log
	exec xfreerdp /sec:nla /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4"
}


function rdesk_one_string_old()
{
	local INSTR
	INSTR=$(zenity --width=400 --entry \
	--title "Remote Desktop" \
	--text "Connection params:" \
	--entry-text "hytera\150113013:******@10.161.53.50")

	[[ -z ${INSTR} ]] && die "Null param input!"

	local HOST
	HOST=$(echo "${INSTR}" | awk -F'@' '{print $2}')
	if [[ -z ${HOST} ]]
	then
		warn "Without domain/user/passwd."
		HOST="${INSTR}"
	else
		local DOMAINUSERPASSWD
		DOMAINUSERPASSWD=$(echo "${INSTR}" | awk -F'@' '{print $1}')
		local PASSWD
		PASSWD=$(echo "${DOMAINUSERPASSWD}" | awk -F':' '{print $2}')
		if [[ -z ${PASSWD} ]]
		then
			warn "Without password."
			local DOMAINUSER
			DOMAINUSER=${DOMAINUSERPASSWD}
		else
			local DOMAINUSER
			DOMAINUSER=$(echo "${DOMAINUSERPASSWD}" | awk -F':' '{print $1}')
		fi
		local USER
		USER=$(echo "${DOMAINUSER}" | awk -F"\\" '{print $2}')
		if [[ -z ${USER} ]]
		then
			warn "Without domain."
			local USER
			USER=${DOMAINUSER}
		else
			local DOMAIN
			DOMAIN=$(echo "${DOMAINUSER}" | awk -F"\\" '{print $1}')
		fi
	fi

	[[ 'X******' == "X${PASSWD}" ]] && PASSWD=Arety2018
	[[ -z ${DOMAIN} ]] || OPTION_DOMAIN="-d ${DOMAIN}"
	[[ -z ${USER}   ]] || OPTION_USER="-u ${USER}"
	[[ -z ${PASSWD} ]] || OPTION_PASSWD="-p ${PASSWD}"

	if ping -c 2 "${HOST}"
	then
		#rdesktop -m -N -C -z -x 0x80 -a 8 -k en-us -a 16 -g 1440x900 \
		#	-r sound:remote -r disk:RDP="$(readlink -f "${HOME}")" -r clipboard:CLIPBOARD \
		#	"${OPTION_DOMAIN}" "${OPTION_USER}" "${OPTION_PASSWD}" "${HOST}"
		#xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" \
		#	+window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}"

		do_xfreerdp "${HOST}" "${DOMAIN}" "${USER}" "${PASSWD}"
	else
		zenity --width=180 --error --text="The host ${HOST} is unreachable!"
		exit 2
	fi
}


function rdesk_one_string()
{
	local INSTR
	INSTR=$(zenity --width=600 --entry \
	--title "Remote Desktop" \
	--text "Connection params:" \
	--entry-text "Hostname:Domain:Administrator:123456:Desciption")
	#--entry-text "hytera\150113013:******@10.161.53.50")

	[[ -z ${INSTR} ]] && die "Null param input!"

	local HOST
	HOST=$(echo "${INSTR}" | awk -F: '{print $1}')
	if [[ -z ${HOST} ]]
	then
		warn "Without host."
	else
		local DOMAIN
		DOMAIN=$(echo "${INSTR}" | awk -F: '{print $2}')
		if [[ -z ${DOMAIN} ]]
		then
			warn "Without domain."
		else
			local USER
			USER=$(echo "${INSTR}" | awk -F: '{print $3}')
			if [[ -z ${USER} ]]
			then
				warn "Without user."
			else
				local PASSWD
				PASSWD=$(echo "${INSTR}" | awk -F: '{print $4}')
				if [[ -z ${PASSWD} ]]
				then
					warn "Without password."
				fi
			fi
		fi
	fi

	#[[ 'X******' == "X${PASSWD}" ]] && PASSWD=Arety2018
	[[ -z ${DOMAIN} ]] || OPTION_DOMAIN="-d ${DOMAIN}"
	[[ -z ${USER}   ]] || OPTION_USER="-u ${USER}"
	[[ -z ${PASSWD} ]] || OPTION_PASSWD="-p ${PASSWD}"

	if ping -c 2 "${HOST}"
	then
		#rdesktop -m -N -C -z -x 0x80 -a 8 -k en-us -a 16 -g 1440x900 \
		#	-r sound:remote -r disk:RDP="$(readlink -f "${HOME}")" -r clipboard:CLIPBOARD \
		#	"${OPTION_DOMAIN}" "${OPTION_USER}" "${OPTION_PASSWD}" "${HOST}"
		#xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" \
		#	+window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}"
		#echo "${HOST}:${DOMAIN}:${USER}:${PASSWD}" >>"${REMOTE_HOST_FILE}"
		echo "${INSTR}" >>"${REMOTE_HOST_FILE}"
		do_xfreerdp "${HOST}" "${DOMAIN}" "${USER}" "${PASSWD}"
	else
		zenity --width=180 --error --text="The host ${HOST} is unreachable!"
		exit 2
	fi
}


function rdesk_one_by_one()
{
	local INSTR
	INSTR=$(zenity --forms --title="Remote Desktop" \
		--text="With params:" \
		--separator="," \
		--add-entry="host" \
		--add-entry="domain" \
		--add-entry="user" \
		--add-password="password")

	[[ -z ${INSTR} ]] && die "Null param input!"

	local HOST
	HOST=$(echo "${INSTR}" | awk -F',' '{print $1}')
	local DOMAIN
	DOMAIN=$(echo "${INSTR}" | awk -F',' '{print $2}')
	local USER
	USER=$(echo "${INSTR}" | awk -F',' '{print $3}')
	local PASSWD
	PASSWD=$(echo "${INSTR}" | awk -F',' '{print $4}')

	[[ 'X******' == "X${PASSWD}" ]] && PASSWD=Arety2018
	if [[ -z ${HOST} ]]
	then
		zenity --width=250 --error --text="Host address is either invalid or null!"
		exit 1
	fi

	if ! ping -c 1 "${HOST}"
	then
		zenity --width=200 --error --text="The host is unreachable!"
		exit 2
	fi

	[[ -z ${DOMAIN} ]] || OPTION_DOMAIN="-d ${DOMAIN}"
	[[ -z ${USER} ]] || OPTION_USER="-u ${USER}"
	[[ -z ${PASSWD} ]] || OPTION_PASSWD="-p ${PASSWD}"

	if ping -c 2 "${HOST}"
	then
		#rdesktop -m -N -C -z -x 0x80 -a 8 -k en-us -a 16 -g 1440x900 \
		#	-r sound:remote -r disk:RDP="$(readlink -f "${HOME}")" -r clipboard:CLIPBOARD \
		#	"${OPTION_DOMAIN}" "${OPTION_USER}" "${OPTION_PASSWD}" "${HOST}"

		#xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" \
		#	+window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}
		
		do_xfreerdp "${HOST}" "${DOMAIN}" "${USER}" "${PASSWD}"
	else
		zenity --width=180 --error --text="The host ${HOST} is unreachable!"
		exit 2
	fi
}


function edit_menu()
{
	if [[ -x /usr/bin/subl ]]
	then
		/usr/bin/subl "$0"
	elif [[ -x /usr/bin/gedit ]]
	then
		/usr/bin/gedit "$0"
	elif [[ -x /usr/bin/nvim ]]
	then
		/usr/bin/nvim "$0"
	fi
}


function edit_connection_list()
{
	if [[ -x /usr/bin/subl ]]
	then
		/usr/bin/subl "${REMOTE_HOST_FILE}"
	elif [[ -x /usr/bin/gedit ]]
	then
		/usr/bin/gedit "${REMOTE_HOST_FILE}"
	elif [[ -x /usr/bin/nvim ]]
	then
		/usr/bin/nvim "${REMOTE_HOST_FILE}"
	fi
}


function rdesktop_connect()
{
	[[ -z "$1" ]] && die "rdesktop_connect(): Null string input."

	HOST="$(echo "$1" | awk -F: '{print $1}')"
	[[ -z "${HOST}" ]] && die "HOST is Null!"

	DOMAIN="$(echo "$1" | awk -F: '{print $2}')"
	[[ -z "${DOMAIN}" ]] && die "DOMAIN is Null!"

	USER="$(echo "$1" | awk -F: '{print $3}')"
	[[ -z "${USER}" ]] && die "USER is Null!"

	PASSWD="$(echo "$1" | awk -F: '{print $4}')"
	[[ -z "${PASSWD}" ]] && die "PASSWD is Null!"

	if ping -c 2 "${HOST}"
	then
		#rdesktop -M -N -C -z -x 0x80 -a 8 -k en-us -a 16 -g 1440x900 \
		#	-r sound:remote -r disk:RDP="$(readlink -f "${HOME}")" -r clipboard:CLIPBOARD \
		#	-d "${DOMAIN}" -u "${USER}" -p "${PASSWD}" "${HOST}"
		#xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" \
		#	+window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}"
		do_xfreerdp "${HOST}" "${DOMAIN}" "${USER}" "${PASSWD}"
	else
		zenity --width=180 --error --text="The host ${HOST} is unreachable!"
		exit 2
	fi
}

# Main Process
#check_exec /usr/bin/rdesktop
check_exec /usr/bin/xfreerdp
check_exec /usr/bin/zenity

[[ -f "${REMOTE_HOST_FILE}" ]] || {
	touch "${REMOTE_HOST_FILE}" || die "Failed to create ${REMOTE_HOST_FILE}!"
}

unset https_proxy

# Debug:
#cat "${REMOTE_HOST_FILE}" | while read X; do
#	echo "FALSE \"${X}\""
#done

#		--column "Host:Domain:User:Passwd" \
#		--column "--------------------------------------------------" \
OPTN=$(zenity --width=500 --height=400 \
		--list --title "Zenity Remote Desktop Dialog" \
		--column "" \
		--hide-header \
		$(cat "${REMOTE_HOST_FILE}" | while read X; do
			echo "${X}"
		done
		) \
		"[Create new remote connection...]" \
		"[Edit connection list...]" \
		"[Edit this menu...]" \
)

#zenity --width=500 --info --text="Confirm selection: ${OPTN}"

case ${OPTN} in
	"[Create new remote connection...]" |	"Manual input: one string")
		rdesk_one_string;;
	"Manual input: one by one")
		rdesk_one_by_one;;
	"[Edit connection list...]")
		edit_connection_list;;
	"[Edit this menu...]")
		edit_menu;;
	*)
		#zenity --width=120 --error --text="Invalid option!";;
		rdesktop_connect "${OPTN}";;
esac

# xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}"
