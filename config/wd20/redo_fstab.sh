#!/bin/bash

set -x
t=`mktemp --tmpdir=/dev/shm`
new_fstab=`mktemp --tmpdir=/dev/shm`

for fstab
do
	base_dir=${fstab%/etc/fstab}
	base_label=${base_dir##*/}
	echo $fstab on $base_dir : $base_label
	cat $fstab > $new_fstab
	sed -i /LABEL=/d $new_fstab
	for i in {1..50}
	do
		blkid -o export /dev/sda$i > $t
		if test -s $t
		then
			unset LABEL
			unset TYPE
			unset MNT
			FSCK="1 2"
			. $t
			if test -z "$LABEL"
			then
				continue
			fi
			case "$LABEL" in
				WD20_BOOT) MNT=/boot/chainloader ;;
				WD20_DIST) MNT=/dist ;;
				WD20_MUSIC) MNT=/Music ;;
				WD20_VM_IMAGES) MNT=/vm_images ;;
				WD20_WORK) MNT=/work ;;
				*) MNT=/$LABEL ;;
			esac
			DIR=$MNT
			if test "$base_label" = "$LABEL"
			then
				DIR=
				MNT=/
				FSCK="1 1"
			fi
			case "$TYPE" in
				ext2|ext3|ext4|xfs)
				echo "LABEL=$LABEL $MNT $TYPE noatime,acl,user_xattr $FSCK" >> $new_fstab
				if test -n "$DIR"
				then
					if test -d $base_dir/$DIR
					then
						:
					else
						rm -f $base_dir/$DIR
						mkdir -p $base_dir/$DIR
					fi
				else
					if test -L $base_dir/$LABEL
					then
						rm -f $base_dir/$LABEL
					elif test -d $base_dir/$LABEL
					then
						rmdir $base_dir/$LABEL
					fi
					ln -sfvn . $base_dir/$LABEL
				fi
				;;
				swap)
				echo "LABEL=$LABEL swap $TYPE defaults 0 0" >> $new_fstab
				;;
				*) ;;
			esac
		fi
	done
	echo
cat $new_fstab > $fstab
	echo
done
rm -fv $t
rm -fv $new_fstab
