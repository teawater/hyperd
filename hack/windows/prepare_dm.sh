#!/bin/bash

BASE_DIR=$(dirname $(readlink -f $0))

cd /mnt

POD_ID=nano-iis
DM_DEV=`${BASE_DIR}/script/get_pod_dm.py ${POD_ID} device`
MNT_NTFS=/mnt/dm/${POD_ID}
mkdir -p ${MNT_NTFS}


# fix ntfs
LOOPDEV=$(losetup -f)
losetup -o $((0x0e400000)) ${LOOPDEV} ${DM_DEV}
ntfsfix ${LOOPDEV}
losetup -d ${LOOPDEV}
sleep 1

# mount ntfs
mount -o loop,offset=$((0x0e400000)) ${DM_DEV} ${MNT_NTFS}

# copy files
mv ${MNT_NTFS}/rootfs/UtilityVM/Files/* ${MNT_NTFS}
cp -avx ${MNT_NTFS}/rootfs/Files/* ${MNT_NTFS}
cp ${BASE_DIR}/hyperstart.exe ${MNT_NTFS}/hyper/hyperstart.exe -rf
#cp ${BASE_DIR}/System_Base ${MNT_NTFS}/Windows/System32/config/SYSTEM -rf


# update registry
reged -I -C ${MNT_NTFS}/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' ${BASE_DIR}/reg/HyperStartService.reg
reged -I -C ${MNT_NTFS}/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' ${BASE_DIR}/reg/W3SVC.reg

# check registry
echo -e 'cd \\\\ControlSet001\\\\Services\\\\HyperStartService\nls\n' | regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM
echo -e 'cd \\\\ControlSet001\\\\Services\\\\W3SVC\nls\n' | regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM

# unmount
cd /mnt && sudo umount ${MNT_NTFS}


