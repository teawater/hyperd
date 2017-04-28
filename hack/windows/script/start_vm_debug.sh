#!/bin/bash
set -e
set -x

if [ $# -ne 1 ];then
  echo "./start_winpe.sh <pod-name>"
  exit 1
fi

BASE_DIR=$(dirname $(readlink -f $0))
ISO_DIR="/home/osboxes/iso"
BOOT_DISK="${ISO_DIR}/NanoBoot.raw"
CDROM_ISO="${ISO_DIR}/Win8PE64net-virtio-vmware.iso"
POD_ID=$1
DM_DEV=`${BASE_DIR}/../common/get_pod_dm.py ${POD_ID} device`
if [ $? -ne 0 ];then
  echo "${POD_ID} doesn't exist"
  exit 1
fi

# umount old device
${BASE_DIR}/umount_dm.sh ${POD_ID}
if [ $? -ne 0 ];then
   echo "umount ${POD_ID} failed"
   exit 1
fi

VM_ID=`${BASE_DIR}/../common/get_pod_dm.py ${POD_ID} vmid`

#UEFI boot, with network adaptor
cd ${ISO_DIR}
echo "Boot NanoServer (Kernel Debug) ...(vnc port: 5909)"
cat <<EOF
qemu-system-x86_64 -enable-kvm -smp 1 -m 1024 
  -bios /usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd 
  -netdev tap,id=network1,ifname=tap2,script=no,downscript=no 
  -device e1000,netdev=network1,mac=00:16:35:AF:94:5B 
  -machine vmport=off 
  -boot order=d,menu=off 
  -drive file=${BOOT_DISK},format=raw 
  -drive file=${DM_DEV},format=raw 
  -vnc :9 
  -chardev stdio,id=mon0 
  -mon chardev=mon0 
  -serial tcp:192.168.1.111:4445 
  -serial tcp:192.168.1.111:8234
EOF

qemu-system-x86_64 -enable-kvm -smp 1 -m 1024 \
  -bios /usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd \
  -netdev tap,id=network1,ifname=tap2,script=no,downscript=no \
  -device e1000,netdev=network1,mac=00:16:35:AF:94:5B \
  -machine vmport=off \
  -boot order=d,menu=off \
  -drive file=${BOOT_DISK},format=raw \
  -drive file=${DM_DEV},format=raw \
  -vnc :9 \
  -chardev stdio,id=mon0 \
  -mon chardev=mon0 \
  -serial tcp:192.168.1.111:4445 \
  -serial tcp:192.168.1.111:8234

