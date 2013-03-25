package virt

import (
	"os/exec"
	"strconv"
	"strings"
	"time"
)

func (vm *VM) Start() ([]byte, error) {
	return exec.Command("/usr/bin/lxc-start", "--name", vm.String(), "--daemon").CombinedOutput()
}

func (vm *VM) Stop() ([]byte, error) {
	return exec.Command("/usr/bin/lxc-stop", "--name", vm.String()).CombinedOutput()
}

func (vm *VM) Shutdown() ([]byte, error) {
	if out, err := exec.Command("/usr/bin/lxc-shutdown", "--name", vm.String()).CombinedOutput(); err != nil {
		return out, err
	}
	vm.WaitForState("STOPPED", 2*time.Second) // may time out, then vm is force stopped
	return vm.Stop()
}

func (vm *VM) AttachCommand(uid int, tty string, command ...string) *exec.Cmd {
	args := []string{"--name", vm.String()}
	if tty != "" {
		args = append(args, "--tty", tty)
	}
	args = append(args, "--", "/usr/bin/sudo", "-i", "-u", "#"+strconv.Itoa(uid), "--")
	args = append(args, command...)
	cmd := exec.Command("/usr/bin/lxc-attach", args...)
	cmd.Env = []string{"TERM=xterm"}
	return cmd
}

func (vm *VM) GetState() string {
	out, err := exec.Command("/usr/bin/lxc-info", "--name", vm.String(), "--state").CombinedOutput()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out)[6:])
}

func (vm *VM) WaitForState(state string, timeout time.Duration) ([]byte, error) {
	return exec.Command("/usr/bin/lxc-wait", "--name", vm.String(), "--state", state, "--timeout", strconv.Itoa(int(timeout.Seconds()))).CombinedOutput()
}
