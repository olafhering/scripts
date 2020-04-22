#!/bin/bash
set -ex
unset LANG
unset ${!LC_*}

d=/dev/disk/by-id/wwn-0x50014ee6afdce999
lbl_pfx=WD20_

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
get_partition_type() {
	local pt=$1
	case "${pt}" in
	ext2) pt=0x83 ;;
	ext3) pt=0x83 ;;
	ext4) pt=0x83 ;;
	xfs)  pt=0x83 ;;
	swap) pt=0x82 ;;
	ntfs) pt=0x07 ;;
	0x*)  pt=${pt};;
	*)    pt=0x83 ;;
	esac
	echo "${pt}"
}
:
get_partition_fs() {
	local fs=$1
	case "${fs}" in
	ext2) fs=ext2 ;;
	ext3) fs=ext3 ;;
	ext4) fs=ext4 ;;
	xfs)  fs=xfs ;;
	swap) fs=swap ;;
	*)    fs= ;;
	esac
	echo "${fs}"
}
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
set_partition_type() {
	local ptype=$1

	${p} set ${part} type $ptype
	udevadm settle
}
:
mk_swap() {
	local label=$1
	dd if=/dev/zero bs=$((1024*1024)) count=1 of=${d}-part${part}
	mkswap -L "${label}" ${d}-part${part}
	udevadm settle
}
:
mkfs_ext2() {
	local label=$1
	dd if=/dev/zero bs=$((1024*1024)) count=42 of=${d}-part${part}
	mkfs -t ext2 -b 2048 -m 1 -L "${label}" ${d}-part${part}
	udevadm settle
	tune2fs -c 0 -i 0 ${d}-part${part}
}
:
mkfs_ext3() {
	local label=$1
	dd if=/dev/zero bs=$((1024*1024)) count=42 of=${d}-part${part}
	mkfs -t ext3 -b 2048 -m 1 -L "${label}" ${d}-part${part}
	udevadm settle
	tune2fs -c 0 -i 0 ${d}-part${part}
}
:
mkfs_ext4() {
	local label=$1
	dd if=/dev/zero bs=$((1024*1024)) count=42 of=${d}-part${part}
	mkfs -t ext4 -b 2048 -m 1 -O flex_bg,uninit_bg -L "${label}" ${d}-part${part}
	udevadm settle
	tune2fs -c 0 -i 0 ${d}-part${part}
}
:
mkfs_xfs() {
	local label=$1
	dd if=/dev/zero bs=$((1024*1024)) count=42 of=${d}-part${part}
	mkfs -t xfs -m crc=0 -L "${label}" ${d}-part${part}
	udevadm settle
}
:
mk_fs() {
	local ptype=$1
	local label=$2
	local pt
	local fs

	pt=` get_partition_type ${ptype} `
	set_partition_type ${pt}
	fs=` get_partition_fs ${ptype} `
	case "${fs}" in
	ext2) mkfs_ext2 "${label}" ;;
	ext3) mkfs_ext3 "${label}" ;;
	ext4) mkfs_ext4 "${label}" ;;
	swap) mk_swap   "${label}" ;;
	xfs)  mkfs_xfs  "${label}" ;;
	esac
	udevadm settle
	: $(( part++ ))
	bdrrpt
}
mp() {
	local -i start=${offset}
	local -i size=$1
	local ptype=$2
	local label=$3
	local -i partition_size=$(( ( ${size} / ${bs} ) ))
	partition_size=$(( ${partition_size} - 1 ))
	$pmp ${start}s $(( ${start} + ${partition_size} ))s
	add_offset ${size}
	bdrrpt
	mk_fs "${ptype}" "${lbl_pfx}${label}"
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
	local ptype=$2
	local label=$3
	local -i partition_size=$(( ( ${size} / ${bs} ) ))
	partition_size=$(( ${partition_size} - 1 ))
	$pml ${start}s $(( ${start} + ${partition_size} ))s
	add_offset ${size}
	add_offset $(( 1024 * 1024 ))
	bdrrpt
	mk_fs "${ptype}" "${lbl_pfx}${label}"
}
mlx() {
	local label=$1
	local -i start=${offset}
	local -i partition_size=$(( ${ds} - 1 ))
	$pml linux-swap ${start}s $(( ${partition_size} ))s
	bdrrpt
	mk_fs "xfs" "${lbl_pfx}${label}"
}
:
$p unit s print
$p mklabel msdos
add_offset $(( 1024 * 1024 ))
mp $(( (1024*1024*1024) * 2)) ext3 BOOT
mp $(( (1024*1024*1024) * 1)) ntfs WINBOOT
mp $(( (1024*1024*1024) * 1)) swap SWAP
me
ml $(( (1024*1024*1024) * 40  )) ntfs WS2008
ml $(( (1024*1024*1024) * 40  )) ntfs WS2008R2
ml $(( (1024*1024*1024) * 40  )) ntfs WS2012
ml $(( (1024*1024*1024) * 40  )) ntfs WS2012R2
ml $(( (1024*1024*1024) * 40  )) ntfs WS2016
ml $(( (1024*1024*1024) * 40  )) ntfs WS2019
ml $(( (1024*1024*1024) * 40  )) ntfs WSa
ml $(( (1024*1024*1024) * 40  )) ntfs WSb
ml $(( (1024*1024*1024) * 40  )) ntfs Windows
ml $(( (1024*1024*1024) * 300 )) ntfs WINDATA
:
ml $(( (1024*1024*1024) * 30  )) ext4 TW
ml $(( (1024*1024*1024) * 12  )) swap 15.7
ml $(( (1024*1024*1024) * 12  )) swap 15.6
ml $(( (1024*1024*1024) * 12  )) swap 15.5
ml $(( (1024*1024*1024) * 12  )) swap 15.4
ml $(( (1024*1024*1024) * 12  )) swap 15.3
ml $(( (1024*1024*1024) * 12  )) swap 15.2
ml $(( (1024*1024*1024) * 12  )) ext4 15.1
ml $(( (1024*1024*1024) * 12  )) ext4 15.0
ml $(( (1024*1024*1024) * 12  )) ext4 42.3
ml $(( (1024*1024*1024) * 12  )) ext4 42.2
ml $(( (1024*1024*1024) * 12  )) ext4 42.1
ml $(( (1024*1024*1024) * 12  )) ext4 13.2
ml $(( (1024*1024*1024) * 12  )) ext4 13.1
ml $(( (1024*1024*1024) * 12  )) ext4 11.4
ml $(( (1024*1024*1024) * 12  )) ext4 SL15DEV
ml $(( (1024*1024*1024) * 12  )) ext4 SL12DEV
ml $(( (1024*1024*1024) * 12  )) ext3 SL11DEV
ml $(( (1024*1024*1024) * 12  )) swap SL15SP7
ml $(( (1024*1024*1024) * 12  )) swap SL15SP6
ml $(( (1024*1024*1024) * 12  )) swap SL15SP5
ml $(( (1024*1024*1024) * 12  )) swap SL15SP4
ml $(( (1024*1024*1024) * 12  )) swap SL15SP3
ml $(( (1024*1024*1024) * 12  )) ext4 SL15SP2
ml $(( (1024*1024*1024) * 12  )) ext4 SL15SP1
ml $(( (1024*1024*1024) * 12  )) ext4 SL15SP0
ml $(( (1024*1024*1024) * 12  )) ext4 SL12SP4
ml $(( (1024*1024*1024) * 12  )) ext4 SL12SP3
ml $(( (1024*1024*1024) * 12  )) ext4 SL12SP2
ml $(( (1024*1024*1024) * 12  )) ext4 SL12SP1
ml $(( (1024*1024*1024) * 12  )) ext4 SL12SP0
ml $(( (1024*1024*1024) * 12  )) ext3 SL11SP4
ml $(( (1024*1024*1024) * 12  )) ext3 SL11SP3
ml $(( (1024*1024*1024) * 12  )) ext3 SL11SP2
ml $(( (1024*1024*1024) * 12  )) ext4 SLED15
ml $(( (1024*1024*1024) * 12  )) ext4 SLED12
ml $(( (1024*1024*1024) * 12  )) ext3 SLED11
ml $(( (1024*1024*1024) * 12  )) swap ArchLinux
ml $(( (1024*1024*1024) * 12  )) swap Debian
ml $(( (1024*1024*1024) * 12  )) swap Fedora
ml $(( (1024*1024*1024) * 12  )) swap Ubuntu
ml $(( (1024*1024*1024) * 15  )) 0xa6 OpenBSD
ml $(( (1024*1024*1024) * 15  )) 0xa6 FreeBSD
ml $(( (1024*1024*1024) * 15  )) 0xa5 NetBSD
ml $(( (1024*1024*1024) * 90  )) xfs  WORK
mlx VM_IMG
:
$p unit s print
$p unit KiB print
$p unit MiB print
$p unit GiB print
