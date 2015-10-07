#!/bin/bash
set -ex
unset LANG
unset ${!LC_*}

d=/dev/disk/by-id/wwn-0x50014ee2590ff8f9

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
	cat /sys/dev/block/$mm/device/block/*/size
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
ml $(( (1024*1024*1024) * 42 )) Privat
ml $(( (1024*1024*1024) * 42 )) Windows
ml $(( (1024*1024*1024) * 42 )) Debian
ml $(( (1024*1024*1024) * 42 )) SLED11
ml $(( (1024*1024*1024) * 42 )) openSUSE
:
mlx dist
:
$p unit s print
$p unit KiB print
$p unit MiB print
$p unit GiB print

