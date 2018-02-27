#!/bin/bash

#et -x
td=`mktemp --directory --tmpdir=/dev/shm`
test -n "${td}" || exit 1
trap "rm -rf \"${td}\"" EXIT
t="${td}/t"
new_fstab="${td}/new_fstab"

add_array() {
	local _spec=${#1}
	local _file=${#2}
	local _vfstype=${#3}
	local _mntops=${#4}
	local _freq=${#5}
	local _passno=${#6}

	if test $fs_len_spec -lt $_spec
	then
		fs_len_spec=$_spec
	fi
	if test $fs_len_file -lt $_file
	then
		fs_len_file=$_file
	fi
	if test $fs_len_vfstype -lt $_vfstype
	then
		fs_len_vfstype=$_vfstype
	fi
	if test $fs_len_mntops -lt $_mntops
	then
		fs_len_mntops=$_mntops
	fi
	if test $fs_len_freq -lt $_freq
	then
		fs_len_freq=$_freq
	fi
	if test $fs_len_passno -lt $_passno
	then
		fs_len_passno=$_passno
	fi
	fs_spec[$idx]=$1
	fs_file[$idx]=$2
	fs_vfstype[$idx]=$3
	fs_mntops[$idx]=$4
	fs_freq[$idx]=$5
	fs_passno[$idx]=$6
	: $((idx++))
}
mm_root=$(printf %x `stat -Lc %d /` )
for fstab
do
	unset fs_spec    fs_len_spec
	unset fs_file    fs_len_file
	unset fs_vfstype fs_len_vfstype
	unset fs_mntops  fs_len_mntops
	unset fs_freq    fs_len_freq
	unset fs_passno  fs_len_passno
	declare -i idx=0 idx_i=0
	declare -i fs_len_spec=0 fs_len_file=0 fs_len_vfstype=0 fs_len_mntops=0 fs_len_freq=0 fs_len_passno=0
	declare -a fs_spec
	declare -a fs_file
	declare -a fs_vfstype
	declare -a fs_mntops
	declare -a fs_freq
	declare -a fs_passno

	case "$fstab" in
		*/etc/fstab) ;;
		*) continue ;;
	esac

	base_dir=${fstab%/etc/fstab}
	if test -z "${base_dir}"
	then
		base_dir=/
	fi
	mm_fstab=$(printf %x `stat -Lc %d ${fstab}` )
	echo $fstab on $base_dir
	DIST_FSCK="1 2"
	DIST_EXT_AUTOFS=",x-systemd.automount,x-systemd.idle-timeout=22"
	DIST_XFS_AUTOFS=",x-systemd.automount,x-systemd.idle-timeout=22"
	if test -e $base_dir/etc/SuSE-release
	then
		if grep -q ^VERSION.*=.*11 $base_dir/etc/SuSE-release
		then
			echo "CODE11"
			DIST_FSCK="0 0"
			DIST_EXT_AUTOFS=",noauto"
			DIST_XFS_AUTOFS=""
		fi
	fi
	cat $fstab > $new_fstab
	sed -i /LABEL=/d $new_fstab
	sed -i /\\/vm_images/d $new_fstab
	for i in {1..50}
	do
		node=/dev/sda${i}
		if ! test -b "${node}"
		then
			continue
		fi
		mm_node=$(printf '%x' $(( (0x`stat -Lc %t ${node}` * 256) + 0x`stat -Lc %T ${node}`)) )
		blkid -o export "${node}" > $t
		if test -s $t
		then
			unset LABEL
			unset TYPE
			unset MNT
			FSCK="${DIST_FSCK}"
			. $t
			if test -z "$LABEL"
			then
				continue
			fi
			case "$LABEL" in
				WD20_BOOT) MNT=/chainloader ;;
				WD20_DIST) MNT=/dist ;;
				WD20_MUSIC) MNT=/Music ;;
				WD20_VM_IMAGES) MNT=/vm_images ;;
				WD20_VM_IMG) MNT=/vm_images ;;
				WD20_WORK) MNT=/work ;;
				*) MNT=/$LABEL ;;
			esac
			DIR=$MNT
			EXT_AUTOFS="${DIST_EXT_AUTOFS}"
			XFS_AUTOFS="${DIST_XFS_AUTOFS}"
			if test "${mm_node}" = "${mm_fstab}"
			then
				DIR=
				MNT=/
				FSCK="1 1"
				EXT_AUTOFS=
				XFS_AUTOFS=
			fi
			opts=defaults
			case "$TYPE" in
				ext2|ext3|ext4)
				OPTS="noatime,acl,user_xattr${EXT_AUTOFS}"
				;;
				xfs)
				OPTS="noatime${XFS_AUTOFS}"
				;;
			esac
			case "$TYPE" in
				ext2|ext3|ext4|xfs)
				add_array LABEL=$LABEL $MNT $TYPE $OPTS $FSCK
				: mm_root ${mm_root} mm_fstab ${mm_fstab} mm_node ${mm_node}
				if pushd "${base_dir}" > /dev/null
				then
					if test "${mm_fstab}" = "${mm_node}"
					then
						: root symlink $LABEL $MNT
						if test -L "${LABEL}"
						then
							rm -f "${LABEL}"
						elif test -d "${LABEL}"
						then
							rmdir "${LABEL}"
						else
							rm -f "${LABEL}"
						fi
						ln -sfvbn . "${LABEL}"
					else
						: mnt directory $LABEL $MNT
						if test -L "${MNT}"
						then
							rm -f "${MNT}"
						elif test -d "${MNT}"
						then
							:
						else
							rm -f "${MNT}"
						fi
						mkdir -vp "./${MNT}"
					fi
					popd > /dev/null
				fi
				;;
				swap)
				add_array LABEL=$LABEL swap $TYPE defaults 0 0
				;;
				*) ;;
			esac
			if test "$MNT" = "/vm_images"
			then
				if pushd "${base_dir}" > /dev/null
				then
					mkdir -vp ./vm_images            ./var/lib/xen/images
					add_array  /vm_images/xen_images  /var/lib/xen/images  bind       bind                   0 0
					popd > /dev/null
				fi
			fi
		fi
	done
	echo
	while test $idx_i -lt $idx
	do
		printf "%- ${fs_len_spec}s %- ${fs_len_file}s %- ${fs_len_vfstype}s %- ${fs_len_mntops}s %- ${fs_len_freq}s %- ${fs_len_passno}s%s\\n" \
			${fs_spec[$idx_i]} \
			${fs_file[$idx_i]} \
			${fs_vfstype[$idx_i]} \
			${fs_mntops[$idx_i]} \
			${fs_freq[$idx_i]} \
			${fs_passno[$idx_i]} \
			""
		: $(( idx_i++ ))
	done >> $new_fstab
	echo
	cat $new_fstab > $fstab
done
