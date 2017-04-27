package main

import (
	"bytes"
	"fmt"
	"io"
	"net"
	"os"
	"strings"

	"github.com/carmark/pseudo-terminal-go/terminal"
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

func interactive_exec(ctl net.Conn, c chan int, hostname *string, shell *string) error {
	//fmt.Printf("[debug] interactive_exec\n")

	term, err := terminal.NewWithStdInOut()
	if err != nil {
		panic(err)
	}
	defer term.ReleaseFromStdInOut() // defer this
	fmt.Println("Ctrl-D/exit/quit to break")
	term.SetPrompt(fmt.Sprintf("%s C:\\Windows\\system32>", *hostname))
	line, err := term.ReadLine()
	for {
		if err == io.EOF {
			term.Write([]byte(line))
			fmt.Println()
			return nil
		}
		if (err != nil && strings.Contains(err.Error(), "control-c break")) || len(line) == 0 {
			line, err = term.ReadLine()
		} else if line == "exit" || line == "quit" {
			break
		} else {
			//term.Write([]byte(line+"\r\n"))
			cmd := ""
			switch *shell {
			case "powershell":
				cmd = fmt.Sprintf("%s %s\r\n", *shell, line)
			case "cmd":
				cmd = fmt.Sprintf("%s /c %s\r\n", *shell, line)
			}
			noninteractive_exec(ctl, c, &cmd)
			line, err = term.ReadLine()
		}
	}

	return nil
}

func noninteractive_exec(ctl net.Conn, c chan int, cmd *string) error {
	//fmt.Printf("[debug] noninteractive_exec\n")
	_, err := ctl.Write([]byte(*cmd))
	if err != nil {
		fmt.Printf("write error:", err)
		return err
	}
	i := <-c
	if i != 0 {
		fmt.Printf("\nFailed\n")
	}
	return nil
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

	if interactive {
		interactive_exec(ctl, c, &hostname, &shell)
	} else {
		noninteractive_exec(ctl, c, &cmd)
	}
}
