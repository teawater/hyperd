Utility for hack windows container
==================================

- hyperd(suppport windows):  https://github.com/hyperhq/hyperd/tree/windows-support
- Dockerfile for image `hyperhq/nanoserver-demo`:  https://github.com/Jimmy-Xu/nanoserver-demo
- hyperstart for windows:  https://github.com/Jimmy-Xu/hyperstart_win


# file description


```
├── common
│   ├── console
│   ├── console.go
│   ├── get_pod_d               # get pod info from leveldb
│   └── reged                   # windows registry edit tool
├── drivers
│   ├── msports-driver          # serial port driver
│   └── network-driver          # network adapter driver
├── hives
│   ├── DefaultUser_Base
│   ├── Sam_Base
│   ├── Security_Base
│   ├── Software_Base
│   └── System_Base
├── hyper
│   ├── hyperstart.exe
│   └── reg
├── hyperctl                    # wrapper for hyperctl
├── script
│   ├── exec_vm.sh              # wrapper for ../common/console, execute command in windows container
│   ├── mount_dm.sh             # mount devicemapper device of pod to /mnt/dm/<pod-id>
│   ├── prepare_dm.sh           # adjust files on devicemapper device
│   ├── start_vm_debug.sh       # start windows vm (kernel debug)
│   ├── start_vm_nano.sh        # start windows vm (boot from devicemapper device)
│   ├── start_vm_test.sh        # serial port connect to remote virtual serial port (USR-VCOM)
│   ├── start_vm_winpe.sh       # start WinPE
│   └── umount_dm.sh            # umount /mnt/dm/<pod-id>
└── util.sh                     # wrapper for script
```

# install dependency
```
$ sudo pip install leveldb

```

# usage

## create windows container
```
cd hack/windows

1. load image
./hyperctl load -i ~/microsoft/nanoserver/nano-iis-demo.tar.gz
./hyperctl images

2. create container
./hyperctl create --name nano-demo hyperhq/nanoserver-demo
./hyperctl list container
./util.sh showdev nano-demo

3. start winpe (modify bcd for the first time)
./util.sh startpe nano-demo

4. prepare files on devicemapper device for nano-demo
./util.sh prepare nano-demo
./util.sh starttest nano-demo

5. start container vm
./hyperctl start naon-demo
./util.sh showsock nano-demo

6. disable driver signature enforcement (via VNC viewer)
press F8 twice

7. execute command(non-interactive)
./hyperctl exec nano-demo powershell hostname
./hyperctl exec nano-demo cmd /c hostname

8. execute command(interactive)
./hyperctl exec nano-demo powershell
> hostname
> pwd
> get-process
> get-service
> netstat -ano
> Invoke-WebRequest -Uri http://localhost |  Select-Object -Expand Content
```


## check runtime info

```
//show unix sock file for windows container
$ ./util.sh showsock nano-demo
srwxr-xr-x 1 root root 0 May  3 17:47 /var/run/hyper/vm-TwJnsaJBAD/win_ctl.sock
srwxr-xr-x 1 root root 0 May  3 17:47 /var/run/hyper/vm-TwJnsaJBAD/win_tty.sock

//show devicemapper device for windows container
$ ./util.sh showdev nano-demo
/dev/mapper/docker-8:16-25223169-71e1dfb0c5bc6e2467f77c628924bce64270161237cc7c534e973c7884a2cbd0

//qemu process for windows VM
$ ps -ef| grep 'qemu.*NanoBoot'
root      70194      1  7 17:47 pts/7    00:01:55 qemu-system-x86_64 -enable-kvm -smp 1 -m 1024 -bios /usr/share/edk2.git/ovmf-x64/OVMF-pure-efi.fd -machine vmport=off -boot order=c,menu=off -drive file=/home/osboxes/iso/NanoBoot.raw,format=raw -drive file=/dev/mapper/docker-8:16-25223169-71e1dfb0c5bc6e2467f77c628924bce64270161237cc7c534e973c7884a2cbd0,format=raw -vnc :8 -serial unix:/var/run/hyper/vm-TwJnsaJBAD/win_ctl.sock,server,nowait -serial unix:/var/run/hyper/vm-TwJnsaJBAD/win_tty.sock,server,nowait
```

