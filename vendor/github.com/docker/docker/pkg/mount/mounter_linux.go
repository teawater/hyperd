package mount

import (
	"os/exec"
	"syscall"

	"github.com/Sirupsen/logrus"
)

func mount(device, target, mType string, flag uintptr, data string) error {
	if mType == "ntfs-3g" {
		args := []string{}
		args = append(args, "-t", mType)
		args = append(args, "-o", data)
		args = append(args, device)
		args = append(args, target)
		logrus.Infof("[mounter_linux.go/mount] command line: /bin/mount %v", args)
		if err := exec.Command("/bin/mount", args...).Run(); err != nil {
			logrus.Infof("[mounter_linux.go/mount] after mount ntfs-3g err:%v", err)
			return err
		}
	} else if err := syscall.Mount(device, target, mType, flag, data); err != nil {
		return err
	}

	// If we have a bind mount or remount, remount...
	if flag&syscall.MS_BIND == syscall.MS_BIND && flag&syscall.MS_RDONLY == syscall.MS_RDONLY {
		//return syscall.Mount(device, target, mType, flag|syscall.MS_REMOUNT, data)
		if err := syscall.Mount(device, target, mType, flag|syscall.MS_REMOUNT, data); err != nil {
			return err
		}
	}
	return nil
}

func unmount(target string, flag int) error {
	return syscall.Unmount(target, flag)
}
