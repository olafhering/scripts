#!/bin/bash
unset LANG
unset ${!LC_*}
set -x
set -e
case "$1" in
	-i)
	zypper -v -v in \
		screen \
		sudo \
		less \
		rpmbuild \
		gcc \
		dbus-1-devel \
		libgcrypt-devel \
		libiw-devel \
		libnl3-devel \
		'pkgconfig(systemd)' \
		automake \
		autoconf \
		libtool \
		flex \
		bison \
		make \
		osc \
		git-core \
		etags \
		ctags \
		indent \
		strace \
		ltrace \
		gdb
	exit 0
	;;
esac
prefix=/dev/shm/wicked
_lib=lib64
_libdir=${prefix}/${_lib}
env \
	CFLAGS="-O1 -g -D_FORTIFY_SOURCE=2 -fstack-protector -Wall -Wextra -Wno-missing-field-initializers -Wno-unused-parameter -Werror $EXTRA_CFLAGS" \
	LDFLAGS="-Wl,-rpath,${_libdir}" \
	bash -x autogen.sh \
	--sysconfdir=${prefix}/etc --prefix=${prefix} --libdir=${_libdir} --libexecdir=${_libdir} --datadir=${prefix}/share --localstatedir=${prefix}/var
mkdir -vp ${prefix}/var/run/wicked
