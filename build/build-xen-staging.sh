#!/bin/bash
set -ex
unset LANG
unset ${!LC_*}

t=`mktemp --tmpdir=/dev/shm`
test -n "$t" || exit 1
_exit() {
	rm -fv "$t"
}
trap _exit EXIT
get_git_branch() {
	local b
	if test -d .git
	then
		b="`git branch | awk '/^*/ { print $0 }'`"
		case "${b}" in
			*"no branch, bisect"*)
			b=${b##* bisect started on }
			b=${b%)}
			;;
			*)
			b="${b#? }"
			echo "$b"
			;;
		esac
	fi
}
branch=`get_git_branch`
cpus=`if grep -Ec 'cpu[0-9]' /proc/stat ; then : ; elif sysctl -n hw.ncpu ; then : ; else echo 1 ; fi`
prefix=/opt/xen/${branch}
libdir=${prefix}/lib64
sysconfdir=${prefix}/etc
proxy=http://probook.fritz.box:3128
OVMF_UPSTREAM_URL=git://probook.fritz.box/ovmf.git
QEMU_UPSTREAM_URL=git://probook.fritz.box/qemu-upstream-unstable.git
QEMU_TRADITIONAL_URL=git://probook.fritz.box/qemu-xen-unstable.git
SEABIOS_UPSTREAM_URL=git://probook.fritz.box/seabios.git
XEN_EXTRAVERSION="-${branch//-/_}"
PKG_SUFFIX="-${branch}"
PKG_RELEASE="`date +%Y%m%d.%H%M%S`"
xen_dentries="
tools
tools/libxc
tools/libxl
xen
docs
stubdom
unmodified_drivers
"
xen_fentries="
Config.mk
Makefile
COPYING
MAINTAINERS
"
for d in $xen_dentries
do
	test -d $d || exit 1
done
for f in $xen_fentries
do
	test -f $f || exit 1
done
if pushd ../gcc-no-g/bin
then
	export PATH="$PWD:$PATH"
	popd
fi
export http_proxy=$proxy
export https_proxy=$proxy
export ftp_proxy=$proxy
cmd=$1
shift
do_make() {
	local target=$1
	if shift ; then : ; fi
	time \
		gmake \
			-j ${cpus} \
			$target \
			debug=n \
			debug_symbols=n \
			V=1 \
			OVMF_UPSTREAM_URL=$OVMF_UPSTREAM_URL \
			QEMU_UPSTREAM_URL=$QEMU_UPSTREAM_URL \
			QEMU_TRADITIONAL_URL=$QEMU_TRADITIONAL_URL \
			SEABIOS_UPSTREAM_URL=$SEABIOS_UPSTREAM_URL \
			OCAMLDESTDIR=$PWD/dist/install/${libdir}/ocaml \
			BOOT_DIR=${prefix}/boot \
			EFI_DIR=${libdir}/efi \
			PKG_SUFFIX=${PKG_SUFFIX} \
			PKG_RELEASE="${PKG_RELEASE}" \
			XEN_EXTRAVERSION="${XEN_EXTRAVERSION}" \
			EXTRA_CFLAGS_XEN_TOOLS=-O1 \
			EXTRA_CFLAGS_QEMU_TRADITIONAL=-O1 \
			EXTRA_CFLAGS_QEMU_XEN=-O1 \
			"$@"
}
case "${cmd}" in
	-c)
	time \
		env \
		./configure \
		--enable-docs \
		--enable-tools \
		--enable-xen \
		--disable-stubdom \
		--enable-ocamltools \
		--enable-rpath \
		--disable-c-stubdom \
		--disable-caml-stubdom \
		--disable-xxx-pv-grub \
		--disable-vtpm-stubdom \
		--disable-vtpmmgr-stubdom \
		--disable-xenstore-stubdom \
		--enable-xxx-ioemu-stubdom \
		--disable-ovmf \
		--disable-systemd \
		--prefix=${prefix} \
		--libdir=${libdir} \
		--sysconfdir=${sysconfdir} \
		"$@"
	;;
	-b)
		rm -rf dist/install
		do_make rpmball "$@"
		for rpm in `for i in dist/*.rpm
		do
			rpm -qp --qf "%{BUILDTIME}-$i\n" $i
		done | sort -nr`
		do
			echo $rpm
			pkg=${rpm#*-}
			mv -v ${pkg} dist/`rpm -qp --qf %{NAME}.rpm ${pkg}`
			break
		done
	;;
	-I)
		rm -rf dist/install
		do_make install "$@"
	;;
	-U)
		rm -rf dist/install
		do_make uninstall "$@"
	;;
	-i)
		rm -rf dist/install
		do_make install DESTDIR=/dev/shm/xen-unstable.$PPID "$@"
	;;
	-u)
		rm -rf dist/install
		do_make uninstall DESTDIR=/dev/shm/xen-unstable.$PPID "$@"
	;;
	-m)
		rm -rf dist/install
		do_make "$@"
	;;
	-t)
		find * -name "*.[ch]" -type f -print0 | sort -z | xargs -0 /bin/ls -1 | cscope -bi- &
#		find * -name "*.[ch]" -type f -print0 | sort -z | xargs -0 /bin/ls -1 | ctags -L - &
		wait
	;;
	-anonymi)
		rsync -avP dist/xen${PKG_SUFFIX}.rpm root@anonymi:
	;;
	-ss)
		rsync -avP dist/xen${PKG_SUFFIX}.rpm root@10.121.8.246:
	;;
esac
