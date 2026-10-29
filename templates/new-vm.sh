#!/usr/bin/env bash
set -euo pipefail

name="${1:?uso: new-vm.sh <nombre> <vcpus> <memoria_MiB>}"
vcpus="${2:-4}"
mem="${3:-8192}"
template="$(dirname "$0")/vm-linux.xml"

img="/var/lib/libvirt/images/${name}.qcow2"
xml="$(mktemp --suffix=.xml)"

sed -e "s/CHANGE-ME/${name}/g" \
    -e "s|<vcpu placement='static'>[0-9]*</vcpu>|<vcpu placement='static'>${vcpus}</vcpu>|" \
    -e "s|<memory unit='MiB'>[0-9]*</memory>|<memory unit='MiB'>${mem}</memory>|" \
    -e "s|<currentMemory unit='MiB'>[0-9]*</currentMemory>|<currentMemory unit='MiB'>${mem}</currentMemory>|" \
    -e "s|<page size='2M' units='[0-9]*'/>|<page size='2M' units='${mem}'/>|" \
    "$template" > "$xml"

sudo virsh define "$xml"
sudo virsh vol-create-as default "${name}.qcow2" --format qcow2 --capacity "${mem}M"
echo "VM '${name}' definida. Arranca con: sudo virsh start ${name}"
