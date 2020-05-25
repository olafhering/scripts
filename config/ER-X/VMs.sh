#!/bin/bash
unset LANG
unset ${!LC_*}
mode=
target=
declare -a x_tech
declare -a x_bitw
declare -a x_dist
declare -a x_opensuse_ver
declare -a x_sle_ver
declare -a x_type
declare -i sle_ver sle_sp
declare -i mac
w_tech=3
x_tech=(
	hv-gen1
	hv-gen2
	pv
	fv
	kv
	ph
)
w_bitw=1
x_bitw=(
	x64
)
#	x86
w_dist=1
x_dist=(
	opensuse
	sles
)
w_opensuse_ver=3
x_opensuse_ver=(
		tw
		11.2
		11.3
		11.4
		12.1
		12.2
		12.3
		13.1
		13.2
		42.1
		42.2
		42.3
		15.0
		15.1
		15.2
)
w_sle_ver=3
x_sle_ver=(
		s11 4
		s12 5
		s15 3
)
w_type=2
x_type=(
	clean
	dev
)
#
str_tech=
i_tech=
str_sp=
i_sp=
str_dist=
i_dist=
i_dist_variant=
str_bitw=
i_bitw=
str_type=
i_type=

fn_print() {
	local mac
	local m6 m5 m4 m3 m2 m1
	local shift

	mac=0
	shift=0
	#
	mac=$(( ${mac} | ( ${i_type} << ${shift} ) ))
	shift=$(( ${shift} + 4 ))
	mac=$(( ${mac} | ( ${i_sp}   << ${shift} ) ))
	shift=$(( ${shift} + 4 ))
	mac=$(( ${mac} | ( ${i_dist} << ${shift} ) ))
	shift=$(( ${shift} + 4 ))
	mac=$(( ${mac} | ( ${i_dist_variant} << ${shift} ) ))
	shift=$(( ${shift} + 4 ))
	mac=$(( ${mac} | ( ${i_bitw} << ${shift} ) ))
	shift=$(( ${shift} + 4 ))
	mac=$(( ${mac} | ( ${i_tech} << ${shift} ) ))
	shift=$(( ${shift} + 4 ))
	mac=$(( ( 0x0815 << 24 ) | ${mac} ))
	#
	shift=0
	#
	m1=$(( ( ${mac} >> ${shift} ) & 0xff ))
	shift=$(( ${shift} + 8 ))
	#
	m2=$(( ( ${mac} >> ${shift} ) & 0xff ))
	shift=$(( ${shift} + 8 ))
	#
	m3=$(( ( ${mac} >> ${shift} ) & 0xff ))
	shift=$(( ${shift} + 8 ))
	#
	m4=$(( ( ${mac} >> ${shift} ) & 0xff ))
	shift=$(( ${shift} + 8 ))
	#
	m5=$(( ( ${mac} >> ${shift} ) & 0xff ))
	shift=$(( ${shift} + 8 ))
	#
	m6=$(( ( ${mac} >> ${shift} ) & 0xff ))
	shift=$(( ${shift} + 8 ))
	#
	#rintf '%-42s %02x:%02x:%02x:%02x:%02x:%02x %012x\n' "${str_tech}-${str_bitw}-${str_dist}-${str_sp}-${str_type}" ${m6} ${m5} ${m4} ${m3} ${m2} ${m1} ${mac}
	name="${str_tech}-${str_bitw}-${str_dist}${str_sp}-${str_type}"
	case "$mode" in
		erx)
			printf '_static_host %02x:%02x:%02x:%02x:%02x:%02x %s\n' ${m6} ${m5} ${m4} ${m3} ${m2} ${m1} "${name}"
		;;
		xl)
			printf "%s=vif=[ 'mac=%02x:%02x:%02x:%02x:%02x:%02x,bridge=br0,type=netfront', ]\\n" "${name}" ${m6} ${m5} ${m4} ${m3} ${m2} ${m1}
		;;
		host_to_mac)
			if test "${name}" = "${target}"
			then
				printf '%02x:%02x:%02x:%02x:%02x:%02x\n' "${m6}" "${m5}" "${m4}" "${m3}" "${m2}" "${m1}"
			fi
		;;
		list)
			echo "${name}"
		;;
		*)
		;;
	esac
}

fn_bitw() {
	local bitw=0

	while test $bitw -lt ${#x_bitw[@]}
	do
		str_bitw=${x_bitw[${bitw}]}
		i_bitw=${bitw}
		fn_print
		: $(( bitw++ ))
	done
}

fn_type() {
	local type=0

	while test $type -lt ${#x_type[@]}
	do
		str_type=${x_type[${type}]}
		i_type=${type}

		fn_bitw
		: $(( type++ ))
	done
}

fn_opensuse() {
	local opensuse_ver
	i_sp=0
	str_sp=

	opensuse_ver=0
	while test ${opensuse_ver} -lt ${#x_opensuse_ver[@]}
	do
		str_dist="${x_opensuse_ver[$opensuse_ver]}"
		str_dist=${str_dist//./}
		i_dist="${opensuse_ver}"
		fn_type
		: $(( opensuse_ver++ ))
	done
}

fn_sles() {
	local sle_ver sle_sp sle_num_sp
	sle_ver=0
	while test ${sle_ver} -lt ${#x_sle_ver[@]}
	do
		str_dist="sle${x_sle_ver[$(( $sle_ver + 0 ))]}"
		sle_num_sp=${x_sle_ver[$(( $sle_ver + 1 ))]}
		i_dist=${sle_ver}

		sle_sp=0
		while test ${sle_sp} -le "${sle_num_sp}"
		do
			str_sp="sp${sle_sp}"
			i_sp=$(( ( ${sle_sp} * 2 ) + 0 ))
			fn_type
			: $(( sle_sp++ ))
		done
		: $(( sle_ver++ ))
		: $(( sle_ver++ ))
	done
}

case "$1" in
	--xl) mode=xl ;;
	--erx) mode=erx ;;
	--mac) mode=host_to_mac ; target=$2 ;;
	--list) mode=list ;;
	-l) mode=list ;;
	*) echo "Usage: $0 [--xl|--erx|--mac|--list]" >&2 ; exit 0 ;;
esac
tech=0
while test ${tech} -lt ${#x_tech[@]}
do
	str_tech=${x_tech[$tech]}
	i_tech=${tech}
	dist=0
	while test ${dist} -lt ${#x_dist[@]}
	do
		i_dist_variant=${dist}
		case "${x_dist[$dist]}" in
			opensuse) fn_opensuse  ;;
			sles) fn_sles ;;
			*) echo "not handled: ${x_dist[$dist]}" >&2 ; exit 1 ;;
		esac
		: $(( dist++ ))
	done
	: $(( tech++ ))
done
#
exit 0
set | grep ^x_
