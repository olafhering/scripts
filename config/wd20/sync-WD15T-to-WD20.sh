#!/bin/bash

cmd=$1
dir=/dev/shm/sync
set -x
mkdir -vp ${dir}
exec 0< /dev/null
exec 1> $dir/log.${cmd}.txt
exec 2>&1
:
r="rsync -avPHS --numeric-ids --delete --delete-before"
n='eval nice -n ${nc}'
i='ionice -c 2 -n ${nc}'
nc=0
if pushd $dir
then
	for nc in {7..1}
	do
		if mkdir -v $nc 2>/dev/null
		then
			break
		fi
	done
	popd
fi
case "$cmd" in
	1)
	$n $i \
	$r \
	/WD15T_11.4G/ /WD20_11.4
	;;
	2)
	$n $i \
	$r \
	/WD15T_13.1G/ /WD20_13.1
	;;
	3)
	;;
	4)
	$n $i \
	$r \
	/WD15T_DIST/ /dist
	;;
	5)
	$n $i \
	$r \
	/WD15T_Factory/ /WD20_Factory 
	;;
	6)
	$n $i \
	$r \
	/WD15T_MUSIC/ /Music
	;;
	7)
	$n $i \
	$r \
	/WD15T_SL11DEV/ /WD20_SL11DEV
	;;
	8)
	$n $i \
	$r \
	/WD15T_SL11SP2GU/ /WD20_SL11SP2
	;;
	9)
	$n $i \
	$r \
	/WD15T_SL11SP3GU/ /WD20_SL11SP3
	;;
	10)
	echo \
	$n $i \
	$r \
	/WD15T_SL12DEV/ /WD20_SL12DEV
	;;
	11)
	$n $i \
	$r \
	/WD15T_SL12DU/ /WD20_SLED12
	;;
	12)
	$n $i \
	$r \
	/WD15T_SL12GU/ /WD20_SL12
	;;
	13)
	$n $i \
	$r \
	/WD15T_VM_IMAGES/ /vm_images
	;;
	14)
	$n $i \
	$r \
	/WD15T_WORK/ /work
	;;
esac
sleep 1
rmdir -v ${dir}/${nc}
