package main

import (
	"bytes"
	"fmt"
	"io"
	"net"
	"os"
	"strings"

	"github.com/chzyer/readline"
)

var gPrompt = ""
var gHostname = ""

func reader(r io.Reader, c chan int, d chan string) {
	tmp := make([]byte, 65535)
	var buf bytes.Buffer
	for {
		n, err := r.Read(tmp[:])
		if err != nil {
			//fmt.Printf("n:%v, err:%v", n, err.Error())
			os.Exit(1)
		}
		buf.WriteString(string(tmp[:n]))
		if strings.HasSuffix(buf.String(), "\n\nDONE\n\n") {
			//fmt.Printf("%v", strings.Replace(buf.String(), "\n\nDONE\n\n", "", -1))
			c <- 0
			d <- fmt.Sprintf("%v", strings.Replace(buf.String(), "\n\nDONE\n\n", "", -1))
			buf.Reset()
		}
	}
}

func interactive_exec(ctl net.Conn, c chan int, d chan string, hostname string, shell string) error {
	//fmt.Printf("[debug] interactive_exec\n")

	l, err := readline.NewEx(&readline.Config{
		Prompt:            fmt.Sprintf("%v%v>", hostname, gPrompt),
		HistoryFile:       "/tmp/demo-history.tmp",
		InterruptPrompt:   "^C",
		EOFPrompt:         "exit",
		HistorySearchFold: true,
	})
	if err != nil {
		panic(err)
	}
	defer l.Close()

	for {
		line, err := l.Readline()
		if err == readline.ErrInterrupt {
			if len(line) == 0 {
				break
			} else {
				continue
			}
		} else if err == io.EOF {
			break
		}

		line = strings.TrimSpace(line)
		switch {
		case line == "quit" || line == "exit":
			goto exit
		case line == "":
			continue
		default:
			cmd := ""
			switch shell {
			case "powershell":
				cmd = fmt.Sprintf("%s %s\n", shell, line)
			case "cmd":
				cmd = fmt.Sprintf("%s /c %s\n", shell, line)
			}
			noninteractive_exec(ctl, c, d, cmd)
		}
	}
exit:
	return nil
}

func noninteractive_exec(ctl net.Conn, c chan int, d chan string, cmd string) error {
	//fmt.Printf("[debug] noninteractive_exec - cmd: [%v]\n", cmd)
	_, err := ctl.Write([]byte(cmd))
	if err != nil {
		fmt.Printf("write error:", err)
		return err
	}

	i := <-c
	if i != 0 {
		fmt.Printf("\nFailed\n")
		os.Exit(1)
	}

	rlt := <-d

	switch cmd {
	case "cmd /c cd":
		gPrompt = fmt.Sprint(substr(rlt, 0, len(rlt)-2))
	case "cmd /c hostname":
		gHostname = fmt.Sprint(substr(rlt, 0, len(rlt)-2))
	default:
		fmt.Printf("%v", rlt)
	}

	return nil
}

func substr(s string, pos, length int) string {
	runes := []rune(s)
	l := pos + length
	if l > len(runes) {
		l = len(runes)
	}
	return string(runes[pos:l])
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
	d := make(chan string)
	go reader(tty, c, d)

	if interactive {
		noninteractive_exec(ctl, c, d, "cmd /c hostname")
		noninteractive_exec(ctl, c, d, "cmd /c cd")
		//hostname = gHostname
		if shell == "powershell" {
			hostname = "PS "
		} else {
			hostname = ""
		}
		interactive_exec(ctl, c, d, hostname, shell)
	} else {
		noninteractive_exec(ctl, c, d, cmd)
	}
}
