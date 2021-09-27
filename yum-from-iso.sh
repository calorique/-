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

function check_root_privilege()
{
	[[ "X${USER}" == "Xroot" ]] || die "Current user is not root!"
}

function usage()
{
	echo "Usage: $0 {iso_image_file} {operation} [-y] package1 package2 package..."
	echo "    iso_image_file: A prepared, version matched ISO image file."
	echo "    operation: could be 'search' / 'provides' / 'install' and so on."
	echo "    -y: Aassume that the answer to any question which would be asked is yes."
	echo "    package: could be single package / packages / group / environment."

}

STEP=1
function step()
{
	note "==>Step ${STEP}/17: $*"
	STEP=$((STEP + 1))
}

step "Check Params"
FORCED=''
ARGV=("$@")
for X in "${!ARGV[@]}"
do
	if [[ "X-y" == "X${ARGV[$X]}" ]]
	then
		FORCED='-y'
		unset "ARGV[$X]"
	fi
done

if [[ ${#ARGV[@]} -lt 3 ]]
then
	usage
	die "Check params and retry!"
fi
echo "${ARGV[*]}"
echo "Params seems OK."

step "Check privilege"
check_root_privilege
id
echo "${USER}"

step "Check CentOS release number"
[[ -f /etc/centos-release ]] || die "/etc/centos-release was not found!"
SYS_RELEASE=$(awk '{print $4}' /etc/centos-release)
[[ -z ${SYS_RELEASE} ]] && die "Failed to fetch the centos release number."
echo "SYS_RELEASE=${SYS_RELEASE}"

step "Check directories"
check_dir /etc/yum.repos.d
#check_dir /var/tmp
check_dir /mnt
echo "Directories are OK."

step "Check ISO image file"
ISO_IMAGE_FILE=$1
check_file "${ISO_IMAGE_FILE}"
stat "${ISO_IMAGE_FILE}"

OPERATION=$2
[[ -z ${OPERATION} ]] && die "Null operation param!"

step "Get timestamp"
TIMPSTAMP=$(date +%s)
echo "Got timestamp ${TIMPSTAMP}."

step "Create mount point directory"
#MNTP=$(mktemp -d -p /var/tmp --suffix=_cdrom)
#if [[ -z ${MNTP} || ! -d ${MNTP} ]]
#then
#	error "Failed to create temp mount point dir!"
#	exit 255
#fi
#stat "${MNTP}"
MNTP=/mnt/repo_cdrom
[[ -e "${MNTP}" ]] || mkdir -p "${MNTP}" || die "mkdir -p ${MNTP} failed!"
mount | grep -E "${MNTP}" && die "${MNTP} is in use!"


step "Mount ISO image"
if ! mount -o loop -t iso9660 "${ISO_IMAGE_FILE}" "${MNTP}"
then
	error "Failed to run: mount -o loop -t iso9660 ${ISO_IMAGE_FILE} ${MNTP}"
	rmdir "${MNTP}"
	exit 255
fi
echo "Mounted ${ISO_IMAGE_FILE} on ${MNTP}."

step "Match CentOS release number"
ISO_RELEASE=$(find "${MNTP}"/Packages/ -name "centos-release-*.rpm" | awk -F- '{gsub(/.*\//,"");gsub(/\./,"-");print $3"."$4"."$5}')
if [[ "X${SYS_RELEASE}" == "X${ISO_RELEASE}" ]]
then
	echo "CentOS release number ${SYS_RELEASE} matched."
else
	echo "The CentOS release number of the system(${SYS_RELEASE}) is different from the ISO(${ISO_RELEASE})."
	umount "${MNTP}"
	rmdir "${MNTP}"
	die "CentOS release number did NOT match!"
fi

step "Backup yum.reopos.d"
TMPCONFD="/etc/yum.repos.d.${TIMPSTAMP}"
if ! mv /etc/yum.repos.d "${TMPCONFD}"
then
	error "Faile to run: mv /etc/yum.repos.d ${TMPCONFD}"
	umount "${MNTP}"
	rmdir "${MNTP}"
	exit 255
fi
echo "Backuped yum.reopos.d as ${TMPCONFD}."

step "Create new yum.reopos.d"
if ! mkdir /etc/yum.repos.d
then
	mv "${TMPCONFD}" /etc/yum.repos.d
	umount "${MNTP}"
	rmdir "${MNTP}"
	exit 255
fi
stat /etc/yum.repos.d

step "Create temporary repo conf"
#TMPREPOF=$(mktemp -p /etc/yum.repos.d --suffix=.repo)
TMPREPOF=/etc/yum.repos.d/repo_cdrom.repo
touch ${TMPREPOF}
if [[ -z ${TMPREPOF} || ! -f ${TMPREPOF} ]]
then
	error "Failed to create temp repo file!"
	rm -rf /etc/yum.repos.d
	mv "${TMPCONFD}" /etc/yum.repos.d
	umount "${MNTP}"
	rmdir "${MNTP}"
	exit 255
fi

REPO_NAME=$(basename "${TMPREPOF}")
[[ -z ${REPO_NAME} ]] && die "Failed to get temporary repo name!"
cat >"${TMPREPOF}" <<EOF
[${REPO_NAME}]
name=CentOS - ${REPO_NAME}
baseurl=file://${MNTP}/
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
stat "${TMPREPOF}"
cat "${TMPREPOF}"

step "Rebuild yum cache"
if ! yum clean all
then
	error "Failed to run: yum clean all!"
	rm -rf /etc/yum.repos.d
	mv "${TMPCONFD}" /etc/yum.repos.d
	umount "${MNTP}"
	rmdir "${MNTP}"
	exit 255
fi

if ! yum makecache
then
	error "Failed to run: yum makecache!"
	rm -rf /etc/yum.repos.d
	mv "${TMPCONFD}" /etc/yum.repos.d
	umount "${MNTP}"
	rmdir "${MNTP}"
	exit 255
fi

unset "ARGV[1]"
unset "ARGV[0]"
PAKAGE_LIST="${ARGV[*]}"

step "Performance ${OPERATION}"
if yum "${OPERATION}" "${FORCED}" "${PAKAGE_LIST}"
then
	info "Operation completed successfully."
else
	error "Failed to run: yum ${OPERATION} ${FORCED} ${PAKAGE_LIST}"
fi

step "Restore environment"
echo -ne "\033[36mRestore yum.repos.d?\033[0m [Y/N]"
#read -n1 ANSWER
read -n1 -r X
echo
case ${X} in
	'y'|'Y')
		rm -rf /etc/yum.repos.d
		mv "${TMPCONFD}" /etc/yum.repos.d
		step "Clean up"
		umount "${MNTP}"
		rmdir "${MNTP}"
		;;
	*)
		;;
esac

step "All done!"

