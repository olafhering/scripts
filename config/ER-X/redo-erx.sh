#!/bin/bash
set -ex
dir="`readlink -f \"${0}\"`"
dir="${dir%/*}"
config_sh="${dir}/erx-config.vbash"
vm_sh="${dir}/VMs.sh"
phys="${dir}/physhosts.txt"
password="$1"
test -n "${password}"
test -f "${config_sh}"
test -f "${vm_sh}"
test -f "${phys}"
pushd /tmp
rm -f 'vm_static_host.txt'
/bin/bash "${vm_sh}" --erx > 'vm_static_host.txt'
time nohup vbash "${config_sh}" "${password}" "${phys}" 'vm_static_host.txt'
rm -f 'vm_static_host.txt'
