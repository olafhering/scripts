#!/bin/bash
set -ex
unset LANG
unset ${!LC_*}

d=/dev/disk/by-id/wwn-0x50014ee6afdce999

get_size()
{
	local d=$1
	local mm

	test -b "${d}" || exit 1
	mm=$(( `stat -L -c 0x%t "${d}"` )):$(( `stat -L -c 0x%T "${d}"` ))
	if test -z "$mm"
	then
		exit 1
	fi
	cat /sys/dev/block/$mm/device/size
}

ds=`get_size ${d}`
bs=512
p="parted -s ${d}"
pmp="${p} mkpart primary"
pme="${p} mkpart extended"
pml="${p} mkpart logical"

: KiB $(( ( ${ds} * ${bs} ) / 1024 ))
: MiB $(( ( ${ds} * ${bs} ) / 1024 / 1024 ))
: GiB $(( ( ${ds} * ${bs} ) / 1024 / 1024 / 1024  ))
: TiB $(( ( ${ds} * ${bs} ) / 1024 / 1024 / 1024 / 1024 ))
echo "scale=2; ( ${ds} * ${bs} ) / 1024                      " | bc
echo "scale=2; ( ${ds} * ${bs} ) / 1024 / 1024               " | bc
echo "scale=2; ( ${ds} * ${bs} ) / 1024 / 1024 / 1024        " | bc
echo "scale=2; ( ${ds} * ${bs} ) / 1024 / 1024 / 1024 / 1024 " | bc
:
: last chance to quit before $d is wiped. Do CTRL-C ...
read
read
read
:
declare -i offset=0
declare -i part=1
:
add_offset() {
	local -i v=$1
	v=$(( ${v} / ${bs} ))
	: current offset ${offset}
	offset=$(( ${offset} + ${v} ))
}
bdrrpt() {
	local -i cnt=5
	udevadm settle --timeout=9
	until blockdev --rereadpt ${d} && test ${cnt} -gt 0
	do
		sleep 0.5
		: $(( cnt-- ))
	done
	udevadm settle --timeout=9

}
set_label() {
	local label=$1
	mkswap -L "${label}" ${d}-part${part}
	udevadm settle --timeout=9
	: $(( part++ ))
	bdrrpt
}
mp() {
	local -i start=${offset}
	local -i size=$1
	local label=$2
	local -i partition_size=$(( ( ${size} / ${bs} ) ))
	partition_size=$(( ${partition_size} - 1 ))
	$pmp ${start}s $(( ${start} + ${partition_size} ))s
	add_offset ${size}
	bdrrpt
	set_label "${label}"
}
me() {
	local -i start=${offset}
	local -i partition_size=$(( ${ds} - 1 ))
	$pme ${start}s $(( ${partition_size} ))s
	add_offset $(( 1024 * 1024 ))
	bdrrpt
	: $(( part++ ))
}
ml() {
	local -i start=${offset}
	local -i size=$1
	local label=$2
	local -i partition_size=$(( ( ${size} / ${bs} ) ))
	partition_size=$(( ${partition_size} - 1 ))
	$pml ${start}s $(( ${start} + ${partition_size} ))s
	add_offset ${size}
	add_offset $(( 1024 * 1024 ))
	bdrrpt
	set_label "${label}"
}
mlx() {
	local label=$1
	local -i start=${offset}
	local -i partition_size=$(( ${ds} - 1 ))
	$pml linux-swap ${start}s $(( ${partition_size} ))s
	bdrrpt
	set_label "${label}"
}
:
$p unit s print
$p mklabel msdos
add_offset $(( 1024 * 1024 ))
mp $(( (1024*1024*1024) * 2)) BOOT
mp $(( (1024*1024*1024) * 1)) WINBOOT
mp $(( (1024*1024*1024) * 8 )) SWAP
me
ml $(( (1024*1024*1024) * 25 )) WS2008
ml $(( (1024*1024*1024) * 25 )) WS2008R2
ml $(( (1024*1024*1024) * 35 )) WS2012
ml $(( (1024*1024*1024) * 35 )) WS2012R2
ml $(( (1024*1024*1024) * 35 )) WS10
ml $(( (1024*1024*1024) * 35 )) WS10R2
ml $(( (1024*1024*1024) * 35 )) WS20
ml $(( (1024*1024*1024) * 250 )) WINDATA
:
ml $(( (1024*1024*1024) * 30 )) TW
ml $(( (1024*1024*1024) * 30 )) Factory
ml $(( (1024*1024*1024) * 10 )) 11.4
ml $(( (1024*1024*1024) * 10 )) 13.1
ml $(( (1024*1024*1024) * 10 )) 13.2
ml $(( (1024*1024*1024) * 10 )) 13.3
ml $(( (1024*1024*1024) * 10 )) 13.4
ml $(( (1024*1024*1024) * 10 )) SL11DEV
ml $(( (1024*1024*1024) * 10 )) SL12DEV
ml $(( (1024*1024*1024) * 10 )) SL13DEV
ml $(( (1024*1024*1024) * 10 )) SL11SP2
ml $(( (1024*1024*1024) * 10 )) SL11SP3
ml $(( (1024*1024*1024) * 10 )) SL11SP4
ml $(( (1024*1024*1024) * 10 )) SL11SP5
ml $(( (1024*1024*1024) * 10 )) SLED11
ml $(( (1024*1024*1024) * 10 )) SLED12
ml $(( (1024*1024*1024) * 10 )) SLED13
ml $(( (1024*1024*1024) * 10 )) SL12
ml $(( (1024*1024*1024) * 10 )) SL12SP1
ml $(( (1024*1024*1024) * 10 )) SL12SP2
ml $(( (1024*1024*1024) * 10 )) SL12SP3
ml $(( (1024*1024*1024) * 10 )) SL12SP4
ml $(( (1024*1024*1024) * 10 )) SL12SP5
ml $(( (1024*1024*1024) * 20 )) ArchLinux
ml $(( (1024*1024*1024) * 20 )) Debian
ml $(( (1024*1024*1024) * 20 )) Fedora
ml $(( (1024*1024*1024) * 20 )) Ubuntu
ml $(( (1024*1024*1024) * 20 )) OpenBSD
ml $(( (1024*1024*1024) * 20 )) FreeBSD
ml $(( (1024*1024*1024) * 20 )) NetBSD
ml $(( (1024*1024*1024) * 10 )) Spare1
ml $(( (1024*1024*1024) * 10 )) Spare2
ml $(( (1024*1024*1024) * 110 )) Music
ml $(( (1024*1024*1024) * 285 )) vm_images
mlx dist
:
$p unit s print
$p unit KiB print
$p unit MiB print
$p unit GiB print
