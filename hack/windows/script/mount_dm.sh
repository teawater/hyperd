#!/bin/bash

set -e
set -x

if [ $# -ne 1 ];then
  echo "./mount_dm.sh <pod-name>"
  exit 1
fi


BASE_DIR=$(dirname $(readlink -f $0))

cd /mnt

POD_ID=$1
DM_DEV=`${BASE_DIR}/../common/get_pod_dm.py ${POD_ID} device`
if [ $? -ne 0 ];then
  echo "${POD_ID} doesn't exist"
  exit 1
fi

MNT_NTFS=/mnt/dm/${POD_ID}
mkdir -p ${MNT_NTFS}

(mount | awk '{print $3}' | grep "${MNT_NTFS}") && (echo "<found old mount, umount first>" ; umount ${MNT_NTFS}) || echo "<no old mount>"
if [ $? -ne 0 ];then
  echo "umount old ${MNT_NTFS} failed"
  exit 1
fi

echo "-------------------------------------"
# fix ntfs
LOOPDEV=$(losetup -f)
losetup -o $((0x0e400000)) ${LOOPDEV} ${DM_DEV}
ntfsfix ${LOOPDEV}
losetup -d ${LOOPDEV}
sleep 1

# mount ntfs
mount -o loop,offset=$((0x0e400000)) ${DM_DEV} ${MNT_NTFS}

echo "-------------------------------------"
echo "<mount point> : ${MNT_NTFS}"
