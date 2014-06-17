package virt

import (
	"fmt"
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
		state, stateErr := vm.GetState()
		if stateErr != nil {
			return commandError("lxc-shutdown failed.", stateErr, out)
		}

		if state != "STOPPED" {
			return commandError("lxc-shutdown failed.", err, out)
		}
	}
	vm.WaitForState("STOPPED", time.Second*5) // may time out, then vm is force stopped
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

func GetVMState(vmId bson.ObjectId) (string, error) {
	out, err := exec.Command("/usr/bin/lxc-info", "--name", VMName(vmId), "--state").CombinedOutput()
	if err != nil {
		return "UNKNOWN", commandError("lxc-info failed ", err, out)
	}
	return strings.TrimSpace(string(out)[6:]), nil
}

func (vm *VM) GetState() (string, error) {
	return GetVMState(vm.Id)
}

func (vm *VM) WaitForState(desiredState string, timeout time.Duration) error {
	tryUntil := time.Now().Add(timeout)

	for {
		currentState, err := vm.GetState()
		if currentState == desiredState {
			break
		}

		if time.Now().After(tryUntil) {
			return fmt.Errorf("Timeout while waiting for VM state, err: %s", err)
		}

		time.Sleep(time.Millisecond * 500)
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

// WaitUntilReady waits until the network is up and the screen binary is
// available and ready to use.
func (vm *VM) WaitUntilReady() error {
	// FIXME: We shouldnt be waiting a fixed duration here, but for a time depenant on server load.
	timeout := time.Second * 30

	isNetworkUp := func() error {
		out, err := exec.Command("/usr/bin/lxc-attach", "--name", vm.String(),
			"--", "/bin/cat", "/sys/class/net/eth0/operstate").CombinedOutput()

		operstate := strings.TrimSpace(string(out))
		if operstate != "up" {
			if err != nil {
				return fmt.Errorf("Network is not up: %s", err)
			}

			return fmt.Errorf("Network is not up, operstate returns: %s", operstate)
		}

		if _, err := exec.Command("/usr/bin/lxc-attach", "--name", vm.String(),
			"--", "/usr/bin/stat", "/usr/bin/screen").CombinedOutput(); err != nil {
			return fmt.Errorf("Screen binary doesn't exist: %s", err)
		}

		// network is up and and screen is also available, we are ready to go
		return nil
	}

	tryUntil := time.Now().Add(timeout)
	var err error
	for {
		if err = isNetworkUp(); err == nil {
			return nil
		}

		if time.Now().After(tryUntil) {
			return fmt.Errorf("Timeout while waiting for VM Network state. Reason: %v", err)
		}

		time.Sleep(time.Millisecond * 500)
	}
}
