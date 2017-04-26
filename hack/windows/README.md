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

4. Communicate via serial port
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
$ sudo ./prepare_dm.sh
```

## start new VM
```
$ sudo ./start_vm.sh
```

$$ communicate via serial port
```
$ sudo ./script/console
```

