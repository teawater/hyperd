#!/bin/bash

set -e
set -x

if [ $# -ne 1 ];then
  echo "./umount_dm.sh <pod-name>"
  exit 1
fi


BASE_DIR=$(dirname $(readlink -f $0))

cd /mnt

POD_ID=$1
DM_DEV=`${BASE_DIR}/../common/get_pod_dm.py ${POD_ID} device`
if [ $? -ne 0 ];then
  echo "${POD_ID} doesn't exist"
  exit 0
fi

MNT_NTFS=/mnt/dm/${POD_ID}
mkdir -p ${MNT_NTFS}

set +e
mount | awk '{print $3}' | grep "${MNT_NTFS}"
if [ $? -eq 0 ];then
  echo "<found mount, umount it>"
  umount ${MNT_NTFS}
  if [ $? -ne 0 ];then
    echo "umount ${MNT_NTFS}  failed"
    exit 1
  else
    echo "umount OK"
  fi
else
  echo "<not mounted>"
fi
set -e

