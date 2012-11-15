package vm

import ()

// #cgo LDFLAGS: -llxc
// #include <lxc/lxc.h>
import "C"

func (vm *VM) Start() {

}

func (vm *VM) Stop() {
	C.lxc_stop(C.CString(vm.String()))
}
