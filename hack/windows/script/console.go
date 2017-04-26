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
	if len(os.Args) < 4 {
		fmt.Printf("%v <hostname> <vmid> <command>\n", os.Args[0])
		os.Exit(1)
	}

	hostname := os.Args[1]
	vmid := os.Args[2]
	cmd := strings.Join(os.Args[3:], " ")
	interactive := false
	shell := ""

	if cmd == "powershell" || cmd == "cmd" {
		interactive = true
		shell = cmd
	}

	var (
		ctl net.Conn
		tty net.Conn
		err error
	)

	ctl, err = net.Dial("unix", fmt.Sprintf("/var/run/hyper/%s/win_ctl.sock", vmid))
	if err != nil {
		panic(err)
	}
	defer ctl.Close()

	tty, err = net.Dial("unix", fmt.Sprintf("/var/run/hyper/%s/win_tty.sock", vmid))
	if err != nil {
		panic(err)
	}
	defer tty.Close()

	c := make(chan int)
	go reader(tty, c)

	for {
		if interactive {
			cmd = ""
			fmt.Printf("\n%v>", hostname)
			fmt.Scanf("%s", &cmd)
			if cmd == "quit" || cmd == "exit" {
				break
			}
			switch shell {
			case "powershell":
				cmd = fmt.Sprintf("%s %s", shell, cmd)
			case "cmd":
				cmd = fmt.Sprintf("%s /c %s", shell, cmd)
			}
		}
		cmd = fmt.Sprintf("%s\n", cmd)
		_, err := ctl.Write([]byte(cmd))
		if err != nil {
			fmt.Printf("write error:", err)
			break
		}
		i := <-c
		if i != 0 {
			fmt.Printf("\nFailed\n")
		}

		if !interactive {
			break
		}
	}
}
