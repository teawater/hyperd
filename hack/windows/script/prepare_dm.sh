#!/bin/bash

set -e
#set -x

if [ $# -ne 1 ];then
  echo "./prepare_dm.sh <pod-name>"
  exit 1
fi


BASE_DIR=$(dirname $(readlink -f $0))
REGED="${BASE_DIR}/../common/reged"
cd /mnt

POD_ID=$1
DM_DEV=`${BASE_DIR}/../common/get_pod_dm.py ${POD_ID} device`
if [ $? -ne 0 ];then
  echo "${POD_ID} doesn't exist"
  exit 1
fi

MNT_NTFS=/mnt/dm/${POD_ID}
mkdir -p ${MNT_NTFS}

echo "######################################"
echo "# umount old device"
echo "######################################"
${BASE_DIR}/umount_dm.sh ${POD_ID}

echo "######################################"
echo "# mount device(ntfs)"
echo "######################################"
sleep 1
${BASE_DIR}/mount_dm.sh ${POD_ID}

echo "######################################"
echo "# copy files"
echo "######################################"
if [ ! -d ${MNT_NTFS}/Windows/System32 ];then
  cp -avx ${MNT_NTFS}/rootfs/UtilityVM/Files/* ${MNT_NTFS}
  cp -avx ${MNT_NTFS}/rootfs/Files/* ${MNT_NTFS}
fi

echo "######################################"
echo "# copy registry"
echo "######################################"
mkdir -p  ${MNT_NTFS}/{hyper,drivers}
cp ${BASE_DIR}/../{hyper,drivers} ${MNT_NTFS}/ -rf
tree ${MNT_NTFS}/{hyper,drivers} -L 2
ls -l ${MNT_NTFS}/hyper/hyperstart.exe

echo "######################################"
echo "# reset registry"
echo "######################################"
sudo rm ${MNT_NTFS}/Windows/System32/config/* -rf
sudo cp -avx ${MNT_NTFS}/rootfs/UtilityVM/Files/Windows/System32/config/* ${MNT_NTFS}/Windows/System32/config/
sudo cp -avx ${MNT_NTFS}/rootfs/Files/Windows/System32/config/* ${MNT_NTFS}/Windows/System32/config/

cp ${BASE_DIR}/../hives/System_Base ${MNT_NTFS}/Windows/System32/config/SYSTEM -rf
cp ${BASE_DIR}/../hives/Software_Base ${MNT_NTFS}/Windows/System32/config/SOFTWARE -rf
cp ${BASE_DIR}/../hives/Security_Base ${MNT_NTFS}/Windows/System32/config/SECURITY -rf
cp ${BASE_DIR}/../hives/Sam_Base ${MNT_NTFS}/Windows/System32/config/SAM -rf
cp ${BASE_DIR}/../hives/DefaultUser_Base ${MNT_NTFS}/Windows/System32/config/DEFAULT -rf

echo "######################################"
echo "# replace computername in registry"
echo "######################################"
CONTAINER_ID=`${BASE_DIR}/../hyperctl list container -p nano-demo -q | awk '{print toupper(substr($1,1,12))}'`
sed -i "s/{HOSTNAME}/${CONTAINER_ID}/g" ${MNT_NTFS}/hyper/reg/hostname.reg
cat ${MNT_NTFS}/hyper/reg/hostname.reg

echo "######################################"
echo "# import registry"
echo "######################################"
set +e
echo "====================================================================="
${REGED} -I -C ${MNT_NTFS}/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' ${MNT_NTFS}/hyper/reg/HyperStartService.reg
echo "====================================================================="
${REGED} -I -C ${MNT_NTFS}/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' ${MNT_NTFS}/hyper/reg/PNP0501.reg
echo "====================================================================="
${REGED} -I -C ${MNT_NTFS}/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' ${MNT_NTFS}/hyper/reg/Serial.reg
echo "====================================================================="
${REGED} -I -C ${MNT_NTFS}/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' ${MNT_NTFS}/hyper/reg/hostname.reg
echo "====================================================================="
${REGED} -I -C ${MNT_NTFS}/Windows/System32/config/DRIVERS 'HKEY_LOCAL_MACHINE\DRIVERS' ${MNT_NTFS}/hyper/reg/DriverFiles.reg
echo "====================================================================="
#${REGED} -I -E -C ${MNT_NTFS}/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' ${MNT_NTFS}/hyper/reg/W3SVC.reg
set -e

echo "######################################"
echo "# check registry"
echo "######################################"
echo "====================================================================="
echo -e 'cd \\\\ControlSet001\\\\Services\\\\HyperStartService\nls\n' | regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM
echo "====================================================================="
echo -e 'cd \\\\ControlSet001\\\\Services\\\\Serial\nls\n' | sudo regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM
echo "====================================================================="
echo -e 'cd \\\\ControlSet001\\\\Enum\\\\ACPI\\\\PNP0501\nls\n' | sudo regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM
echo "====================================================================="
echo -e 'cd \\\\ControlSet001\\\\Enum\\\\ACPI\\\\PNP0501\\\\1\nls\n' | sudo regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM
echo "====================================================================="
echo -e 'cd \\\\DriverDatabase\\\\DriverFiles\\\\serial.sys\nls\n' | sudo regshell -F ${MNT_NTFS}/Windows/System32/config/DRIVERS
echo "====================================================================="
echo -e 'cd \\\\ControlSet001\\\\Control\\\\ComputerName\\\\ComputerName\nls\n' | sudo regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM
echo -e 'cd \\\\ControlSet001\\\\Services\\\\Tcpip\\\\Parameters\nls\n' | sudo regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM
echo "====================================================================="
#echo -e 'cd \\\\ControlSet001\\\\Services\\\\W3SVC\nls\n' | regshell -F ${MNT_NTFS}/Windows/System32/config/SYSTEM

echo "######################################"
echo "# unmount"
echo "######################################"
cd /mnt
sleep 1
${BASE_DIR}/umount_dm.sh ${POD_ID}


