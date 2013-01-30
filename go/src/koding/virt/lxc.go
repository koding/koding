package virt

import (
	"errors"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

func (vm *VM) StartCommand() *exec.Cmd {
	return exec.Command("/usr/bin/lxc-start", "--name", vm.String(), "--daemon")
}

func (vm *VM) StopCommand() *exec.Cmd {
	return exec.Command("/usr/bin/lxc-stop", "--name", vm.String())
}

func (vm *VM) ShutdownCommand() *exec.Cmd {
	return exec.Command("/usr/bin/lxc-shutdown", "--name", vm.String(), "--timeout", "5")
}

func (vm *VM) AttachCommand(uid int, tty string, command ...string) *exec.Cmd {
	args := []string{"--name", vm.String()}
	if tty != "" {
		args = append(args, "--tty", tty)
	}
	args = append(args, "--", "/usr/bin/sudo", "-i", "-u", "#"+strconv.Itoa(uid))
	args = append(args, command...)
	cmd := exec.Command("/usr/bin/lxc-attach", args...)
	//cmd.Env = []string{"TERM=xterm"}
	return cmd
}

func (vm *VM) WaitForRunning(timeout time.Duration) error {
	until := time.Now().Add(timeout)
	for time.Now().Before(until) {
		out, err := exec.Command("/usr/bin/lxc-info", "--name", vm.String(), "--state").CombinedOutput()
		if err != nil {
			return err
		}
		if strings.Contains(string(out), "RUNNING") {
			return nil
		}
		time.Sleep(time.Second / 10)
	}
	return errors.New("timeout")
}
