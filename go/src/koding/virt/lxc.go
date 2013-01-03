package virt

import (
	"fmt"
	"os/exec"
)

func (vm *VM) Start() error {
	return exec.Command("/usr/bin/lxc-start", "--name", vm.String(), "--daemon").Run()
}

func (vm *VM) Stop() error {
	return exec.Command("/usr/bin/lxc-stop", "--name", vm.String()).Run()
}

func (vm *VM) Shutdown() error {
	return exec.Command("/usr/bin/lxc-stop", "--name", vm.String(), "--timeout", "10").Start()
}

func (vm *VM) AttachCommand(uid int, command ...string) *exec.Cmd {
	args := []string{"--name", vm.String(), "--", "sudo", "-i", "-u", fmt.Sprintf("#%d", uid)}
	args = append(args, command...)
	cmd := exec.Command("/usr/bin/lxc-attach", args...)
	//cmd.Env = []string{"TERM=xterm"}
	return cmd
}
