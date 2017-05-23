#!/bin/bash
set -e
#set -x

BASE_DIR=$(dirname $(readlink -f $0))
ISO_DIR="/home/osboxes/iso"
BOOT_DISK="${ISO_DIR}/NanoUEFIQemuGuest.qcow2"

cd ${ISO_DIR}
echo "Boot NanoServer from 2k16 ...(vnc port: 5909)"
cat <<EOF
qemu-system-x86_64 -enable-kvm -smp 1 -m 1024
  -bios /usr/share/edk2.git/ovmf-x64/OVMF-pure-efi.fd
  -netdev tap,id=network1,ifname=tap2,script=no,downscript=no 
  -device e1000,netdev=network1,mac=00:16:35:AF:94:5B 
  -machine vmport=off 
  -boot order=d,menu=off 
  -drive file=${BOOT_DISK},format=qcow2,cache=none 
  -vnc :9 
  -chardev stdio,id=mon0 
  -mon chardev=mon0 
EOF

qemu-system-x86_64 -enable-kvm -smp 1 -m 1024 \
  -bios /usr/share/edk2.git/ovmf-x64/OVMF-pure-efi.fd \
  -netdev tap,id=network1,ifname=tap2,script=no,downscript=no \
  -device virtio-net-pci,netdev=network1,mac=00:16:35:AF:94:5B \
  -machine vmport=off \
  -boot order=d,menu=off \
  -drive file=${BOOT_DISK},format=qcow2,cache=none \
  -vnc :9 \
  -chardev stdio,id=mon0 \
  -mon chardev=mon0

