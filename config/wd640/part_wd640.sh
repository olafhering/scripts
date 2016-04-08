#!/bin/bash
set -ex
unset LANG
unset ${!LC_*}

d=/dev/disk/by-id/wwn-0x50014ee2590ff8f9
d=/dev/disk/by-id/scsi-350014ee2590ff8f9

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
	udevadm settle
	until blockdev --rereadpt ${d} && test ${cnt} -gt 0
	do
		sleep 0.5
		: $(( cnt-- ))
	done
	udevadm settle

}
set_label() {
	local label=$1
	mkswap -L "${label}" ${d}-part${part}
	udevadm settle
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
	${p} set ${part} type 0x8e
	bdrrpt
	dd if=/dev/urandom bs=42M count=42 of=${d}-part${part}
	cryptsetup luksFormat --use-random --cipher=aes-xts-plain64 --key-size=512 ${d}-part${part}
	bdrrpt
}
:
$p unit s print
$p mklabel msdos
add_offset $(( 1024 * 1024 ))
mp $(( (1024*1024*1024) * 2  )) BOOT
mp $(( (1024*1024*1024) * 1  )) WINBOOT
mp $(( (1024*1024*1024) * 42 )) UDF
me
ml $(( (1024*1024*1024) * 42 )) Android
ml $(( (1024*1024*1024) * 42 )) Win7
ml $(( (1024*1024*1024) * 42 )) Win8
ml $(( (1024*1024*1024) * 42 )) Win10
ml $(( (1024*1024*1024) * 42 )) FreeBSD
ml $(( (1024*1024*1024) * 42 )) OpenBSD
ml $(( (1024*1024*1024) * 42 )) NetBSD
:
mlx crypt_lvm
:
$p unit s print
$p unit KiB print
$p unit MiB print
$p unit GiB print

