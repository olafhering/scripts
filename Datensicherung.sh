#!/bin/bash
# vim: ts=3 shiftwidth=3 noexpandtab nowrap
unset LANG
unset ${!LC_*}
Verzeichnis='/Datensicherung'
Sprache='de_DE.UTF-8'
chvt 8
(
	declare -a UUIDs
	declare -a Werte
	declare -i i
	declare -i Sekunden=123
	td='/dev/shm'
	echo
	echo "    Starte '$0'. Jetzt erstmal die richtige Uhrzeit aus dem Internet holen ..."
	env -i LC_ALL=${Sprache} df -hTP "${Verzeichnis}"
	env -i LC_ALL=${Sprache} mkdir -p "${td}/c"
	chronyc -h 127.0.0.1,::1 waitsync 600 0.1 0.0 1

	while read
	do
		Werte=( ${REPLY} )
		fs="${Werte[0]}"
		uuid="${Werte[1]}"
		mountpoint="${Werte[2]}"
		mnt="/${fs}-${uuid}"
		conf="${td}/c/${uuid}"

		if test -n "${mountpoint}"
		then
			continue
		fi

		case "${fs}" in
			ntfs)
				UUIDs+=( "${uuid}" )
				env -i LC_ALL=${Sprache} mkdir -vpm0 "${mnt}"
				mount -v -t ntfs-3g -o "ro,users,gid=users,fmask=133,dmask=022,locale=${Sprache}" -U "${uuid}" "${mnt}"
				;;
			vfat)
				UUIDs+=( "${uuid}" )
				env -i LC_ALL=${Sprache} mkdir -vpm0 "${mnt}"
				mount -v -t vfat -o 'ro' -U "${uuid}" "${mnt}"
				;;
			*)
				continue
				;;
		esac
		cat > "${conf}" <<_EOF_
config_version	1.2
#cmd_postexec	/bin/true
no_create_root	1
cmd_cp	/usr/bin/cp
cmd_rm	/usr/bin/rm
cmd_rsync	/usr/bin/rsync
cmd_logger	/usr/bin/logger
cmd_du	/usr/bin/du
cmd_rsnapshot_diff	/usr/bin/rsnapshot-diff
retain	${uuid//-/}	12345
verbose	2
loglevel	3
logfile	/var/log/Datensicherung.log
lockfile	/run/Datensicherung.pid
rsync_long_args	--sparse --hard-links --delete --numeric-ids --relative --delete-excluded
one_fs	1
link_dest	1
use_lazy_deletes	1
snapshot_root	${Verzeichnis}
exclude	*.sys

backup	${mnt}/	Kopie/
_EOF_
	done < <( lsblk -no FSTYPE,UUID,MOUNTPOINT -x FSTYPE )


	env -i LC_ALL=${Sprache} df -hTPlt xfs -t fuseblk -t vfat
	for UUID in "${UUIDs[@]}"
	do
		conf="${td}/c/${UUID}"
		/usr/bin/time -f %E rsnapshot -c "${conf}" "${UUID//-/}"
		/usr/bin/time -f %E rsnapshot -c "${conf}" du | head -n 5
	done
	env -i LC_ALL=${Sprache} df -hTPlt xfs -t fuseblk -t vfat

	echo "   Fertig. Ausschalten in ${Sekunden} Sekunden "
	sync
	i=${Sekunden}
	while test "${i}" -gt 0
	do
		echo -n '.'
		i=$(( ${i} - 1 ))
	done
	echo
	i=${Sekunden}
	while test "${i}" -gt 0
	do
		echo -n '.'
		sleep 1
		i=$(( ${i} - 1 ))
	done
	sync
	chvt 1
	systemctl --no-pager poweroff
	exit 0
) 2>&1 | tee /dev/tty8
