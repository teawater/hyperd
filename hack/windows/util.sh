#!/bin/bash

BASE_DIR=$(dirname $(readlink -f $0))

function do_showdev(){
  sudo PS4='Line ${LINENO}: ' ${BASE_DIR}/common/get_pod_dm.py $1 device
}

function do_showsock(){
  VM_ID=`sudo ${BASE_DIR}/common/get_pod_dm.py $1 vmid`
  sudo ls -l /var/run/hyper/${VM_ID}/win*.sock
}

function do_startpe(){
  sudo PS4='Line ${LINENO}: ' ${BASE_DIR}/script/start_vm_winpe.sh $1
}

function do_startnano(){
  sudo PS4='Line ${LINENO}: ' ${BASE_DIR}/script/start_vm_nano.sh $1
}

function do_starttest(){
  sudo PS4='Line ${LINENO}: ' ${BASE_DIR}/script/start_vm_test.sh $1
}

function do_prepare(){
  sudo PS4='Line ${LINENO}: ' ${BASE_DIR}/script/prepare_dm.sh $1
}

function do_mount(){
  sudo PS4='Line ${LINENO}: ' ${BASE_DIR}/script/mount_dm.sh $1
}

function do_umount(){
  sudo PS4='Line ${LINENO}: ' ${BASE_DIR}/script/umount_dm.sh $1
}

function do_startkd(){
  sudo PS4='Line ${LINENO}: ' ${BASE_DIR}/script/start_vm_debug.sh $1
}

function do_createtap(){
  for i in tap1 tap2
  do
    ifconfig $i >/dev/null 2>&1
    if [ $? -ne 0 ];then
      echo "create $i"
      sudo ip tuntap add dev $i mode tap
      sudo ip link set $i up promisc on
      sudo brctl addif br0 $i
    else
      echo "$i is exist"
    fi
  done
}

function show_usage(){
  cat <<EOF 
./util.sh <action> <pid-id>
<action>:
  showdev	show devicemapper device of pod
  showsock      show unix sock file for pod
  startpe	start WinPE with qemu(with devicemapper device of pod mounted)
  prepare       prepare files on devicemapper device
  startnano     start nanoserver with qemu
  mount		mount devicemapper device of pod
  umount	umount devicemapper device of pod
  startkd       start nanoserver with qemu for kernel debug
  starttest     start nanoserver with qemu(connect remote serial port)
  createtap     create tap1 and tap2
EOF
  exit 1
}

#### main ####
if [ $# -ne 2 -a $1 != "createtap" ];then
   show_usage
fi

case $1 in
showdev)
	do_showdev $2
	;;
showsock)
	do_showsock $2
	;;
startpe)
	do_startpe $2
	;;
prepare)
	do_prepare $2
	;;
startnano)
	do_startnano $2
	;;
mount)
	do_mount $2
	;;
umount)
	do_umount $2
	;;
startkd)
	do_startkd $2
	;;
starttest)
	do_starttest $2
	;;
createtap)
	do_createtap
	;;
*)
	show_usage
esac
