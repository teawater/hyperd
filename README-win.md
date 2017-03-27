
# Build

```
cd ~/gopath/src/github.com/hyperhq/hyperd
make
```

# Run hyperd with ntfs support

```
//prepare required file in /run/hyper/
$ sudo cp ~/gopath/src/github.com/hyperhq/hyperstart/build/{kernel,hyper-initrd.img} /run/hyper/

//start hyperd
$ sudo ./hyperd --v=3 --host tcp://0.0.0.0:2375 --host unix:///var/run/hyperd.sock --storage-driver=devicemapper --storage-opt dm.fs=ntfs-3g --storage-opt dm.mkfsarg="-U" --storage-opt dm.mkfsarg="-p 2048" --storage-opt dm.mkfsarg="-f" --storage-opt dm.mountopt="offset=$((0x0e400000))" 
```

# Load image

```
sudo ./hyperctl load -i ~/microsoft/nanoserver/nanoserver-latest.tar.gz
```

# Create container

```
sudo ./hyperctl create --name nanoserver microsoft/nanoserver
```

# List

```
$ sudo ./hyperctl list
POD ID              POD Name            VM name             Status
nanoserver          nanoserver          vm-LSjCbwgRbn       running

$ sudo ./hyperctl list container
Container ID                                                       Name                POD ID              Status
6ceded1a0e61290609f7f584d9b9f16d0ee173eb3dbb770b5915cd3bdd542f4e   nanoserver          nanoserver          pending

$ ps -ef | grep qemu
root       5174      1  0 19:51 ?        00:00:19 /bin/qemu-system-x86_64 -machine pc-i440fx-2.0,accel=kvm,usb=off -global kvm-pit.lost_tick_policy=discard -cpu host -kernel /run/hyper/kernel -initrd /run/hyper/hyper-initrd.img -append console=ttyS0 panic=1 no_timer_check -realtime mlock=off -no-user-config -nodefaults -no-hpet -rtc base=utc,driftfix=slew -no-reboot -display none -boot strict=on -m 128 -smp 1 -qmp unix:/var/run/hyper/vm-LSjCbwgRbn/qmp.sock,server,nowait -serial unix:/var/run/hyper/vm-LSjCbwgRbn/console.sock,server,nowait -device virtio-serial-pci,id=virtio-serial0,bus=pci.0,addr=0x2 -device virtio-scsi-pci,id=scsi0,bus=pci.0,addr=0x3 -chardev socket,id=charch0,path=/var/run/hyper/vm-LSjCbwgRbn/hyper.sock,server,nowait -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=charch0,id=channel0,name=sh.hyper.channel.0 -chardev socket,id=charch1,path=/var/run/hyper/vm-LSjCbwgRbn/tty.sock,server,nowait -device virtserialport,bus=virtio-serial0.0,nr=2,chardev=charch1,id=channel1,name=sh.hyper.channel.1 -fsdev local,id=virtio9p,path=/var/run/hyper/vm-LSjCbwgRbn/share_dir,security_model=none -device virtio-9p-pci,fsdev=virtio9p,mount_tag=share_dir -daemonize -pidfile /var/run/hyper/vm-LSjCbwgRbn/pidfile -D /var/log/hyper/qemu/vm-LSjCbwgRbn.log

```

# View devicemapper

```
// list devicemapper for nanoserver container
$ ll /dev/mapper 
total 0
crw------- 1 root root 10, 236 Mar 24 18:48 control
...
lrwxrwxrwx 1 root root       7 Mar 24 19:50 docker-8:16-8388674-base -> ../dm-4
lrwxrwxrwx 1 root root       7 Mar 24 20:34 docker-8:16-8388674-f33437de971b2260481a87147acd07c84f9631b534c59583f247cdea4bbd4ed2 -> ../dm-6    <<<<<<
lrwxrwxrwx 1 root root       7 Mar 24 19:51 docker-8:16-8388674-f33437de971b2260481a87147acd07c84f9631b534c59583f247cdea4bbd4ed2-init -> ../dm-5
lrwxrwxrwx 1 root root       7 Mar 24 19:42 docker-8:16-8388674-pool -> ../dm-0


// show disk partition(GPT, ESP+MSR+NTFS)
$ sudo parted /dev/mapper/docker-8:16-8388674-f33437de971b2260481a87147acd07c84f9631b534c59583f247cdea4bbd4ed2 print
Error: The backup GPT table is corrupt, but the primary appears OK, so that will be used.
OK/Cancel? OK
Model: Linux device-mapper (thin) (dm)
Disk /dev/mapper/docker-8:16-8388674-f33437de971b2260481a87147acd07c84f9631b534c59583f247cdea4bbd4ed2: 10.7GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size    File system  Name     Flags
 1      1049kB  105MB   104MB   fat32        ESP      boot
 2      105MB   239MB   134MB                primary  msftres
 3      239MB   10.7GB  10.5GB  ntfs         primary



// mount device of nanoserver 
$ sudo mkdir -p /mnt/docker_ntfs
$ sudo mount -o loop,offset=$((0x0e400000)) /dev/mapper/docker-8:16-8388674-f33437de971b2260481a87147acd07c84f9631b534c59583f247cdea4bbd4ed2 /mnt/docker_ntfs


// list dir and files
$ sudo tree /mnt/docker_ntfs -L 3
/mnt/docker_ntfs
├── id
└── rootfs
    ├── dev
    │   ├── console
    │   ├── pts
    │   └── shm
    ├── etc
    │   ├── hostname
    │   ├── hosts
    │   ├── mtab -> /proc/mounts
    │   └── resolv.conf
    ├── Files
    │   ├── License.txt
    │   ├── ProgramData
    │   ├── Program\ Files
    │   ├── Program\ Files\ (x86)
    │   ├── Users
    │   └── Windows
    ├── Hives
    │   ├── DefaultUser_Delta
    │   ├── Sam_Delta
    │   ├── Security_Delta
    │   ├── Software_Delta
    │   └── System_Delta
    ├── proc
    ├── sys
    └── UtilityVM
        └── Files

16 directories, 12 files
```