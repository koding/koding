package virt

import (
	"os/exec"
	"strconv"
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

func (vm *VM) AttachCommand(uid int, pty string, command ...string) *exec.Cmd {
	args := []string{"--name", vm.String()}
	if pty != "" {
		args = append(args, "--pty", pty, "--setsid")
	}
	args = append(args, "--", "/usr/bin/sudo", "-i", "-u", "#"+strconv.Itoa(uid))
	args = append(args, command...)
	cmd := exec.Command("/usr/bin/lxc-attach", args...)
	cmd = exec.Command("/bin/bash")
	//cmd.Env = []string{"TERM=xterm"}
	return cmd
}
