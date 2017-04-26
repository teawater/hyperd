package main

import (
	"bytes"
	"fmt"
	"io"
	"net"
	"os"
	"strings"
)

func reader(r io.Reader, c chan int) {
	tmp := make([]byte, 65535)
	var buf bytes.Buffer
	for {
		n, err := r.Read(tmp[:])
		if err != nil {
			fmt.Printf("err:%v", err.Error())
			c <- 1
			return
		}
		buf.WriteString(string(tmp[:n]))
		if strings.HasSuffix(buf.String(), "\n\nDONE\n\n") {
			fmt.Printf("%v", strings.Replace(buf.String(), "\n\nDONE\n\n", "", -1))
			c <- 0
		}
	}
}

func main() {
	if len(os.Args) != 2 {
		fmt.Printf("%v <vmid>", os.Args[0])
		os.Exit(1)
	}

	var (
		ctl net.Conn
		tty net.Conn
		err error
	)
	ctl, err = net.Dial("unix", fmt.Sprintf("/var/run/hyper/%s/win_ctl.sock", os.Args[1]))
	if err != nil {
		panic(err)
	}
	defer ctl.Close()

	tty, err = net.Dial("unix", fmt.Sprintf("/var/run/hyper/%s/win_tty.sock", os.Args[1]))
	if err != nil {
		panic(err)
	}
	defer tty.Close()

	c := make(chan int)
	go reader(tty, c)

	for {
		cmd := "powershell Get-Process\n"
		fmt.Printf("\n>%v", cmd)
		_, err := ctl.Write([]byte(cmd))
		if err != nil {
			fmt.Printf("write error:", err)
			break
		}
		i := <-c
		if i == 0 {
			fmt.Printf("\nOK\n")
		} else {
			fmt.Printf("\nFailed\n")
		}
	}
}
