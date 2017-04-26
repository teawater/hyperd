#!/bin/bash

if [ $# -ne 1 ];then
  echo "./start_vm.sh <pod-name>"
  exit 1
fi

BASE_DIR=$(dirname $(readlink -f $0))
BOOT_DISK=/home/osboxes/iso/NanoBoot.raw
POD_ID=$1
DM_DEV=`${BASE_DIR}/script/get_pod_dm.py ${POD_ID} device`
VM_ID=`${BASE_DIR}/script/get_pod_dm.py ${POD_ID} vmid`

#UEFI boot, with network adaptor and seiral port
qemu-system-x86_64 -enable-kvm -smp 1 -m 1024 \
  -bios /usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd \
  -netdev tap,id=network0,ifname=tap1,script=no,downscript=no \
  -device e1000,netdev=network0,mac=52:55:00:d1:55:01 \
  -machine vmport=off \
  -boot order=c,menu=off \
  -drive file=${BOOT_DISK},format=raw \
  -drive file=${DM_DEV},format=raw \
  -vnc :8 \
  -chardev stdio,id=mon0 \
  -mon chardev=mon0 \
  -serial unix:/var/run/hyper/${VM_ID}/win_ctl.sock,server,nowait \
  -serial unix:/var/run/hyper/${VM_ID}/win_tty.sock,server,nowait

