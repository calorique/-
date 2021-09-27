#!/bin/bash

function usage(){
	echo "Usage: $0 {NUMBER}"
}

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

# Main Process
function kmgtpe() {
	[[ $# -eq 1 ]] || die "$(usage)"
	X=$1
	[[ $X -lt 0 ]] && die "Too less."
	[[ $X -gt 9223372036854775807 ]] && die "Too large."

	# 1K = 1024 ^ 1 = 1024
	# 1M = 1024 ^ 2 = 1048576
	# 1G = 1024 ^ 3 = 1073741824
	# 1T = 1024 ^ 4 = 1099511627776
	# 1P = 1024 ^ 5 = 1125899906842624
	# 1E = 1024 ^ 6 = 1152921504606846976
	# 1B = 1024 ^ 7 = Numerical result out of range
	# 9223372036854775807 = 7E 1023P 1023T 1023G 1023M 1023K 1023 = 0x7FFF,FFFF,FFFF,FFFF = 2^(64-1)-1

	E=$((X / 1152921504606846976)); X=$((X % 1152921504606846976))
	P=$((X / 1125899906842624)); X=$((X % 1125899906842624))
	T=$((X / 1099511627776)); X=$((X % 1099511627776))
	G=$((X / 1073741824)); X=$((X % 1073741824))
	M=$((X / 1048576)); X=$((X % 1048576))
	K=$((X / 1024)); X=$((X % 1024))

	echo "${E}E ${P}P ${T}T ${G}G ${M}M ${K}K ${X}Byte(s)"
}

TOTAL=0

# for X in $(dmesg | grep -i 'BIOS-e820:' | grep 'usable$' | cut -d'[' -f3 | cut -d']' -f1 | cut -d' ' -f2)
for X in $(dmesg | grep -i 'reserve setup_data:' | grep 'usable$' | cut -d'[' -f3 | cut -d']' -f1 | cut -d' ' -f2)
do
	echo "$X"
	Y=$(echo "$X" | cut -d '-' -f 1)
	Z=$(echo "$X" | cut -d '-' -f 2)
	R=$((Z - Y))
	echo -e "$Z - $Y = $R \n$(kmgtpe ${R})"
	TOTAL=$((TOTAL + R))
	echo
done
[[ -z ${X} ]] && die "The log of e820 were not found in dmesg!"

warn "--------------Total------------------"
note "${TOTAL}"

TOTAL=$(kmgtpe "${TOTAL}")

info "${TOTAL}"
