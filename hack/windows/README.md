Utility for hack windows container
==================================

# file description


```
1. Get container info from leveldb
- script/get_pod_dm.py

2. Prepare file on DM device 
- prepare_dm.sh
- mount_dm.sh
- umount_dm.sh

3. Start VM
- start_vm.sh

4. Execute command via serial port
- exec_vm.sh
- script/console.go
```

# usage

## create windows container
```
//load xjimmyshcn/nanoserver-hyper-iis:latest image
$ sudo ./hyperctl load -i ~/microsoft/nanoserver/nanoserver-hyper-iis.tar.gz

//create nano-iis container
$ sudo ./hyperctl create --name nano-iis xjimmyshcn/nanoserver-hyper-iis
```

## prepare files on DM device

```
//get hostname by pod-id
$ sudo script/get_pod_dm.py nano-iis hostname

//get DM device by pod-id
$ sudo script/get_pod_dm.py nano-iis device

//get vm Id by pod-id
$ sudo script/get_pod_dm.py nano-iis vmid

//adjust file on DM device
$ sudo ./prepare_dm.sh nano-iis
```

## start new VM
```
$ sudo ./start_vm.sh nano-iis
```

## check runtime info

```
//check related sock file
$ VM_ID=`sudo ./script/get_pod_dm.py nano-iis vmid`
$ sudo ls -l /var/run/hyper/${VM_ID}/win*.sock
srwxr-xr-x 1 root root 0 Apr 26 12:16 /var/run/hyper/vm-pAvbkwmOHY/win_ctl.sock
srwxr-xr-x 1 root root 0 Apr 26 12:16 /var/run/hyper/vm-pAvbkwmOHY/win_tty.sock

//check related devicemapper device
$ DM_DEV=`sudo ./script/get_pod_dm.py nano-iis device`
$ ll ${DM_DEV}*
lrwxrwxrwx 1 root root 8 Apr 26 13:00 /dev/mapper/docker-8:16-16797762-01c6e28b9522c8a624191eabeb2b9b29631e245d6b3633b791ce2ed7759b415f -> ../dm-24
lrwxrwxrwx 1 root root 8 Apr 25 18:07 /dev/mapper/docker-8:16-16797762-01c6e28b9522c8a624191eabeb2b9b29631e245d6b3633b791ce2ed7759b415f-init -> ../dm-23

//qemu process for windows VM
$ ps -ef| grep 'qemu.*NanoBoot'
root      87003  86997 99 13:10 pts/8    00:00:37 qemu-system-x86_64 -enable-kvm -smp 1 -m 1024 -bios /usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd -netdev tap,id=network0,ifname=tap1,script=no,downscript=no -device e1000,netdev=network0,mac=52:55:00:d1:55:01 -machine vmport=off -boot order=c,menu=off -drive file=/home/osboxes/iso/NanoBoot.raw,format=raw -drive file=/dev/mapper/docker-8:16-16797762-01c6e28b9522c8a624191eabeb2b9b29631e245d6b3633b791ce2ed7759b415f,format=raw -vnc :8 -chardev stdio,id=mon0 -mon chardev=mon0 -serial unix:/var/run/hyper/vm-pAvbkwmOHY/win_ctl.sock,server,nowait -serial unix:/var/run/hyper/vm-pAvbkwmOHY/win_tty.sock,server,nowait
```


## execute command

```
$ sudo ./exec_vm.sh nano-iis powershell

$ sudo ./exec_vm.sh nano-iis powershell get-process

$ sudo ./exec_vm.sh nano-iis cmd

$ sudo ./exec_vm.sh nano-iis cmd /c hostname
```

