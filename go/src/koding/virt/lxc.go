package virt

import (
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

func (vm *VM) AttachCommand(command ...string) *exec.Cmd {
	args := []string{"--name", vm.String(), "--"}
	args = append(args, command...)
	return exec.Command("/usr/bin/lxc-attach", args...)
}
