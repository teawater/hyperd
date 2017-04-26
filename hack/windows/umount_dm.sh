#!/bin/bash

if [ $# -ne 1 ];then
  echo "./umount_dm.sh <pod-name>"
  exit 1
fi


BASE_DIR=$(dirname $(readlink -f $0))

cd /mnt

POD_ID=$1
DM_DEV=`${BASE_DIR}/script/get_pod_dm.py ${POD_ID} device`
MNT_NTFS=/mnt/dm/${POD_ID}
mkdir -p ${MNT_NTFS}

(mount | awk '{print $3}' | grep "${MNT_NTFS}") && (echo "<found mount, umount it>" ; umount ${MNT_NTFS}) || echo "<no mount>"
if [ $? -ne 0 ];then
  echo "umount ${MNT_NTFS}  failed"
  exit 1
fi

echo "OK"
