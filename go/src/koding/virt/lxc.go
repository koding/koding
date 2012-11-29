package virt

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"syscall"
)

/*
#cgo LDFLAGS: -llxc
#include <lxc/lxc.h>
#include <sys/types.h>
extern pid_t get_init_pid(const char *name);
*/
import "C"

func (vm *VM) Start() error {
	return exec.Command("/usr/bin/unshare", "-m", "--", "/usr/bin/lxc-start", "-d", "-n", vm.String()).Run()
}

func (vm *VM) Stop() error {
	if C.lxc_stop(C.CString(vm.String())) != 0 {
		return fmt.Errorf("stop failed")
	}
	return nil
}

func (vm *VM) Shutdown() error {
	process, err := vm.GetInitProcess()
	if err != nil {
		return err
	}
	err = process.Signal(syscall.SIGPWR)
	if err != nil {
		return err
	}
	return nil
}

func (vm *VM) GetInitProcess() (*os.Process, error) {
	pid := int(C.get_init_pid(C.CString(vm.String())))
	if pid < 0 {
		return nil, fmt.Errorf("VM not running")
	}

	cmdline, err := ioutil.ReadFile(fmt.Sprintf("/proc/%d/cmdline", pid))
	if err != nil {
		return nil, err
	}
	if string(cmdline)[:len(cmdline)-1] != "/sbin/init" { // cut off trailing null char
		return nil, fmt.Errorf("not init process")
	}

	process, err := os.FindProcess(pid)
	if err != nil {
		return nil, err
	}

	return process, nil
}
