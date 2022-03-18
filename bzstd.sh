#!/bin/bash

PROGNAME=$(basename "$0")
ERRLOG="/tmp/${PROGNAME}.err.log"

function usage(){
	echo "Usage: $0 DEST_PATH SOURCE_PATH"
}

function die() {
	echo -e "\033[31m$*\033[0m"
	exit 255
}

function error() {
	echo -e "\033[31m$*\033[0m"
}

function warn() {
	echo -e "\033[33m$*\033[0m"
}

function note() {
	echo -e "\033[32m$*\033[0m"
}

function debug_print() {
	echo -e "\033[32mDebug: $*\033[0m"
}

function check_delete_file()
{
	NEW_BACKUP_FILE=$1
	[[ -z ${NEW_BACKUP_FILE} ]] && die "Failed: check_delete_file() received null param"

	if [[ -e "${NEW_BACKUP_FILE}" ]]
	then
		warn "Existed backup file: ${NEW_BACKUP_FILE}"
		while true
		do
			echo -en "Remove it and create again? [y/n] "
			read -r X
			case ${X} in
				y|Y|yes|Yes|YES)
					rm -vf "${NEW_BACKUP_FILE}"
					break;
					;;
				n|N|no|No|NO)
					exit 0
					;;
				*)
					error "Invalid input!"
					continue
					;;
			esac
		done
	fi
}

# Main Process
[[ $# -eq 2 ]] || die "$(usage)"

if [[ "X$(uname -s)" == "XDarwin" ]]
then
	READLINK="greadlink"
elif [[ "X$(uname -s)" == "XLinux" ]]
then
	READLINK="readlink"
else
	READLINK="readlink"
fi

# Check system
for X in 'basename' 'cat' 'echo' 'ls' 'zstd' 'read' "${READLINK}" 'tar'
do
	command -v "${X}" >/dev/null || die "Failed: command -v ${X}"
done

[[ -z $2 ]] && die "Null param 2"
BACKPATH=$(${READLINK} -f "$2")
[[ -z ${BACKPATH} ]] && die "Failed: ${READLINK} -f $2"

debug_print "BACKPATH=${BACKPATH}"

[[ -z $1 ]] && die "Null param 1"
OUTDIR=$(${READLINK} -f "$1")
[[ -z ${OUTDIR} ]] && die "Failed: ${READLINK} -f $1"
[[ -d "${OUTDIR}" ]] || die "Invalid path: ${OUTDIR}"

debug_print "OUTDIR=${OUTDIR}"

if [[ -d "${BACKPATH}" ]]
then
	debug_print "${BACKPATH} is a directory."
	DIRNAME=$(basename "${BACKPATH}")
	[[ -z ${DIRNAME} ]] && die "Failed: basename ${BACKPATH}"

	NEW_BACKUP_FILE="${OUTDIR}/${DIRNAME}.tar.zst"


	debug_print "NEW_BACKUP_FILE=${NEW_BACKUP_FILE}"

	check_delete_file "${NEW_BACKUP_FILE}"

	WORKDIR=$(${READLINK} -f "${BACKPATH}"/..)
	cd "${WORKDIR}" || die "Failed: cd ${WORKDIR}"

	#if tar cvfp - "${DIRNAME}" | lz4 - "${NEW_BACKUP_FILE}" 2>"${ERRLOG}"
	if tar -pv -I zstd -c "${DIRNAME}" -f "${NEW_BACKUP_FILE}" 2>"${ERRLOG}"
	then
		cat "${ERRLOG}"
		ls -lh "${NEW_BACKUP_FILE}"
	else
		cat "${ERRLOG}"
	fi
elif [[ -f "${BACKPATH}" ]]
then
	debug_print "${BACKPATH} is a file."
	FILENAME=$(basename "${BACKPATH}")
	[[ -z ${FILENAME} ]] && die "Failed: basename ${BACKPATH}"

	NEW_BACKUP_FILE="${OUTDIR}/${FILENAME}.tar.zst"
	check_delete_file "${NEW_BACKUP_FILE}"

	WORKDIR=$(dirname "${BACKPATH}")
	cd "${WORKDIR}" || die "Failed: cd ${WORKDIR}"
	#if tar cvfp - "${FILENAME}" | lz4 - "${NEW_BACKUP_FILE}" 2>"${ERRLOG}"
	if tar -pv -I zstd -c "${FILENAME}" -f "${NEW_BACKUP_FILE}" 2>"${ERRLOG}"
	then
		cat "${ERRLOG}"
		ls -lh "${NEW_BACKUP_FILE}"
	else
		cat "${ERRLOG}"
	fi
else
	die "Invalid path: ${BACKPATH}"
fi
# End

# Uncompress command line (for examle):
#tar -I zstd -xvf /tmp/test.tar.zst -C ./
