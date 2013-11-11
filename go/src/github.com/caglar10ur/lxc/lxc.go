// Copyright © 2013, S.Çağlar Onur
// Use of this source code is governed by a LGPLv2.1
// license that can be found in the LICENSE file.
//
// Authors:
// S.Çağlar Onur <caglar@10ur.org>

// +build linux

//Go (golang) Bindings for LXC (Linux Containers)
//
//This package implements Go bindings for the LXC C API.
package lxc

// #cgo linux LDFLAGS: -llxc -lutil
// #include <lxc/lxc.h>
// #include <lxc/lxccontainer.h>
// #include "lxc.h"
import "C"

import (
	"os"
	"path/filepath"
	"unsafe"
)

const (
	// Timeout
	WAIT_FOREVER int = iota - 1
	DONT_WAIT
)

func init() {
	if os.Geteuid() != 0 {
		panic("Running as non-root.")
	}
}

func NewContainer(name string) *Container {
	cname := C.CString(name)
	defer C.free(unsafe.Pointer(cname))
	return &Container{container: C.lxc_container_new(cname, nil)}
}

// Increments reference counter of the container object
func GetContainer(lxc *Container) bool {
	return C.lxc_container_get(lxc.container) == 1
}

// Decrements reference counter of the container object
func PutContainer(lxc *Container) bool {
	return C.lxc_container_put(lxc.container) == 1
}

// Returns LXC version
func Version() string {
	return C.GoString(C.lxc_get_version())
}

// Returns default config path
func DefaultConfigPath() string {
	return C.GoString(C.lxc_get_default_config_path())
}

// Returns the names of containers on the system.
func ContainerNames() []string {
	// FIXME: Support custom config paths
	matches, err := filepath.Glob(filepath.Join(DefaultConfigPath(), "/*/config"))
	if err != nil {
		return nil
	}

	for i, v := range matches {
		matches[i] = filepath.Base(filepath.Dir(v))
	}
	return matches
}

// Returns the containers on the system.
func Containers() []Container {
	var containers []Container

	for _, v := range ContainerNames() {
		containers = append(containers, *NewContainer(v))
	}
	return containers
}
