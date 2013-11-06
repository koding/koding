package process

import (
	"errors"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
)

func KillPid(pid int) error {
	p, err := os.FindProcess(pid)
	if err != nil {
		return err
	}

	err = p.Kill()
	if err != nil {
		return err
	}

	return nil
}

func RunCmd(cmdString string, args ...string) ([]byte, error) {
	if len(cmdString) == 0 {
		return nil, errors.New("empty string, aborting")
	}

	commands := strings.SplitAfterN(cmdString, " ", 2)

	if args == nil {
		args := make([]string, 0)
		if len(commands) >= 2 {
			args = strings.SplitAfter(commands[1], " ")
			for i, val := range args {
				args[i] = strings.TrimSpace(val)
			}
		}
	}

	command := strings.TrimSpace(commands[0])
	cmd := exec.Command(command, args...)

	// Print into the terminal
	// cmd.Stdout = os.Stdout
	// cmd.Stderr = os.Stderr

	// Open in background
	// cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}

	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, err
	}

	return out, nil
}

func SignalPid(pid int, call syscall.Signal) error {
	process, err := os.FindProcess(pid)
	if err != nil {
		log.Printf("failed to find process: %s\n", err)
	}

	err = process.Signal(call)
	if err != nil {
		return err
	}
	return nil
}

func StopPid(pid int) error {
	return SignalPid(pid, syscall.SIGSTOP)
}

func CheckPid(pid int) error {
	process, err := os.FindProcess(pid)
	if err != nil {
		log.Printf("failed to find process: %s\n", err)
	}

	err = process.Signal(syscall.Signal(0))
	if err != nil {
		return errors.New("pid terminated or not owned by me")
	}
	return nil // pid exists
}

func SignalWatcher() {
	// For future reference, if we can do stuff for ctrl+c
	signals := make(chan os.Signal, 1)
	signal.Notify(signals)
	for {
		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM:
			log.Fatalf("received '%s' signal; exiting", signal)
			os.Exit(1)
		default:
			log.Printf("received '%s' signal; unhandled", signal)
		}
	}
}

/*func RunSshCmd(cmdString string) string {
	key := new(keychain)
	err := key.LoadPEM("/Users/fatih/.ssh/koding_rsa")
	if err != nil {
		log.Println(err)

	}

	config := &ssh.ClientConfig{
		User: "ubuntu",
		Auth: []ssh.ClientAuth{
			ssh.ClientAuthKeyring(key),
		},
	}

	client, err := ssh.Dial("tcp", "ktl.koding.com:22", config)
	if err != nil {
		log.Println("Failed to dial", err)
	}

	session, err := client.NewSession()
	if err != nil {
		log.Println("Failed to create session", err)
	}
	defer session.Close()

	var b bytes.Buffer
	session.Stdout = &b
	if err := session.Run("/bin/hostname"); err != nil {
		log.Println("Failed to run: ", err)
	}

	return b.String()
}
*/
