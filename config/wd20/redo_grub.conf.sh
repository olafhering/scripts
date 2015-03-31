#!/bin/bash
set -e

for i in /*/etc/grub.conf
do
	D=0x`stat -c '%D' $i`
	maj=$(( ($D & 0xfff00) >> 8 ))
	min=$(( $D & 0xff  ))
	dev=`grep "^$maj:$min$" /sys/block/*/*/dev || :`
	if test -n "${dev}"
	then
		part=${dev%/*}
		disk=${part%/*}
		part=${part##*/}
		disk=${disk##*/}
		partnum=${part#${disk}}
		grub_partnum=$(( $partnum - 1 ))
		disk_dev=${dev%/*}
		disk_dev=`cat ${disk_dev%/*}/dev`
		disk_by_id=
		for by_id in /dev/disk/by-id/ata-*
		do
			if test "$(( 0x`stat -Lc %t $by_id`)):$((0x`stat -Lc %T $by_id`))" = "$disk_dev"
			then
				disk_by_id=$by_id
				break
			fi
		done
		echo "$i: disk $disk part $part partnum $partnum grub_partnum $grub_partnum disk_dev $disk_dev $disk_by_id"
		cat $i
		(
			echo "setup --stage2=/boot/grub/stage2 --force-lba (hd0,$grub_partnum) (hd0,$grub_partnum)"
			echo quit
		)
		devicemap=${i%/*}
		devicemap=${devicemap%/*}
		if test -f ${devicemap}/boot/grub/device.map
		then
			head ${devicemap}/boot/grub/device.map
			(
				echo "(hd0)	$disk_by_id"
			) > ${devicemap}/boot/grub/device.map
		fi
	fi
	echo
done
