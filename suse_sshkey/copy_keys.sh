#!/usr/bin/env bash
set -ex
cd "${0%/*}"
ssh=
sshconf=
if test -e /etc/ssh/sshd_config
then
  sshconf=$_
  ssh=/etc/ssh
elif test -e /etc/sshd_config
then
  sshconf=$_
  ssh=/etc
fi
if test -z "${ssh}"
then
  : "sshd_config is neither in /etc/ssh nor in /etc"
  exit 1
fi
cp -p *key *pub ${ssh}
: "OSTYPE ${OSTYPE}"
case "${OSTYPE}" in
  linux|linux-gnu|cygwin)
    chown -v --reference=${sshconf} "${ssh}"/*key
    chown -v --reference=${sshconf} "${ssh}"/*pub
  ;;
  *)
  : "${OSTYPE} not recognized"
    chown 0:0 "${ssh}"/*key
    chown 0:0 "${ssh}"/*pub
  ;;
esac
chmod 400 "${ssh}"/*key
chmod 444 "${ssh}"/*pub
