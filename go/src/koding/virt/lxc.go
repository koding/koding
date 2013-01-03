package virt

import (
	"fmt"
	"os/exec"
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

func (vm *VM) AttachCommand(uid int, command ...string) *exec.Cmd {
	args := []string{"--name", vm.String(), "--", "sudo", "-i", "-u", fmt.Sprintf("#%d", uid)}
	args = append(args, command...)
	cmd := exec.Command("/usr/bin/lxc-attach", args...)
	//cmd.Env = []string{"TERM=xterm"}
	return cmd
}
