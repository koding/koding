package virt

import (
	"errors"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"labix.org/v2/mgo/bson"
)

func (vm *VM) Start() error {
	if out, err := exec.Command("/usr/bin/lxc-start", "--name", vm.String(), "--daemon").CombinedOutput(); err != nil {
		return commandError("lxc-start failed.", err, out)
	}
	return vm.WaitForState("RUNNING", time.Second)
}

func (vm *VM) Stop() error {
	if out, err := exec.Command("/usr/bin/lxc-stop", "--name", vm.String()).CombinedOutput(); err != nil {
		return commandError("lxc-stop failed.", err, out)
	}
	return vm.WaitForState("STOPPED", time.Second)
}

func (vm *VM) Shutdown() error {
	if out, err := exec.Command("/usr/bin/lxc-shutdown", "--name", vm.String()).CombinedOutput(); err != nil {
		if vm.GetState() != "STOPPED" {
			return commandError("lxc-shutdown failed.", err, out)
		}
	}
	vm.WaitForState("STOPPED", 5*time.Second) // may time out, then vm is force stopped
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
	cmd.Env = []string{"TERM=xterm-256color"}
	return cmd
}

func GetVMState(vmId bson.ObjectId) string {
	out, err := exec.Command("/usr/bin/lxc-info", "--name", VMName(vmId), "--state").CombinedOutput()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out)[6:])
}

func (vm *VM) GetState() string {
	return GetVMState(vm.Id)
}

func (vm *VM) WaitForState(state string, timeout time.Duration) error {
	tryUntil := time.Now().Add(timeout)
	for vm.GetState() != state {
		if time.Now().After(tryUntil) {
			return errors.New("Timeout while waiting for VM state.")
		}
		time.Sleep(time.Second / 10)
	}
	return nil
}

func (vm *VM) SendMessageToVMUsers(message string) error {
	cmd := exec.Command("/usr/bin/lxc-attach", "--name", vm.String(), "--", "/usr/bin/wall", "--nobanner")
	cmd.Stdin = strings.NewReader(message)
	if out, err := cmd.CombinedOutput(); err != nil {
		return commandError("wall failed.", err, out)
	}
	return nil
}

func (vm *VM) WaitForNetwork(timeout time.Duration) error {
	// precaution for bad input
	if timeout == 0 {
		timeout = time.Second * 5
	}

	isNetworkUp := func() bool {
		// neglect error because it's not important and we also going to timeout
		out, _ := exec.Command("/usr/bin/lxc-attach", "--name", vm.String(),
			"--", "/bin/cat", "/sys/class/net/eth0/operstate").CombinedOutput()

		if strings.TrimSpace(string(out)) == "up" {
			return true
		}

		return false
	}

	tryUntil := time.Now().Add(timeout)
	for {
		if up := isNetworkUp(); up {
			return nil
		}

		if time.Now().After(tryUntil) {
			return errors.New("Timeout while waiting for VM Network state.")
		}

		time.Sleep(time.Millisecond * 100)
	}
}
