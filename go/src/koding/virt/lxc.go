package virt

import (
	"os"
	"syscall"
)

/*
#cgo LDFLAGS: -llxc
#include <lxc/lxc.h>
#include <lxc/conf.h>
#include <lxc/caps.h>
extern int get_init_pid(const char *name);
*/
import "C"

func (vm *VM) Start() {
	C.lxc_caps_init()

	conf := C.lxc_conf_init()
	C.lxc_start(C.CString(vm.String()), nil, conf)
}

func (vm *VM) Stop() {
	C.lxc_stop(C.CString(vm.String()))
}

func (vm *VM) Shutdown() {
	p, err := os.FindProcess(vm.GetInitPid())
	if err != nil {
		panic(err)
	}
	err = p.Signal(syscall.SIGPWR)
	if err != nil {
		panic(err)
	}
}

func (vm *VM) GetInitPid() int {
	return int(C.get_init_pid(C.CString(vm.String())))
}
