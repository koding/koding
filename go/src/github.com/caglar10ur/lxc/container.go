// Copyright © 2013, S.Çağlar Onur
// Use of this source code is governed by a LGPLv2.1
// license that can be found in the LICENSE file.
//
// Authors:
// S.Çağlar Onur <caglar@10ur.org>

// +build linux

package lxc

// #include <lxc/lxc.h>
// #include <lxc/lxccontainer.h>
// #include "lxc.h"
import "C"

import (
	"strconv"
	"strings"
	"sync"
	"time"
	"unsafe"
)

type Container struct {
	container *C.struct_lxc_container
	sync.RWMutex
}

// Returns container's name
func (lxc *Container) Name() string {
	lxc.RLock()
	defer lxc.RUnlock()
	return C.GoString(lxc.container.name)
}

// Returns whether the container is already defined or not
func (lxc *Container) Defined() bool {
	lxc.RLock()
	defer lxc.RUnlock()
	return bool(C.lxc_container_defined(lxc.container))
}

// Returns whether the container is already running or not
func (lxc *Container) Running() bool {
	lxc.RLock()
	defer lxc.RUnlock()
	return bool(C.lxc_container_running(lxc.container))
}

// Returns the container's state
func (lxc *Container) State() State {
	lxc.RLock()
	defer lxc.RUnlock()
	return stateMap[C.GoString(C.lxc_container_state(lxc.container))]
}

// Returns the container's PID
func (lxc *Container) InitPID() int {
	lxc.RLock()
	defer lxc.RUnlock()
	return int(C.lxc_container_init_pid(lxc.container))
}

// Returns whether the daemonize flag is set
func (lxc *Container) Daemonize() bool {
	lxc.RLock()
	defer lxc.RUnlock()
	return bool(lxc.container.daemonize != 0)
}

// Sets the daemonize flag
func (lxc *Container) SetDaemonize() {
	lxc.Lock()
	defer lxc.Unlock()
	C.lxc_container_want_daemonize(lxc.container)
}

// Freezes the running container
func (lxc *Container) Freeze() bool {
	lxc.Lock()
	defer lxc.Unlock()
	return bool(C.lxc_container_freeze(lxc.container))
}

// Unfreezes the frozen container
func (lxc *Container) Unfreeze() bool {
	lxc.Lock()
	defer lxc.Unlock()
	return bool(C.lxc_container_unfreeze(lxc.container))
}

// Creates the container using given template and arguments
func (lxc *Container) Create(template string, args []string) bool {
	lxc.Lock()
	defer lxc.Unlock()

	ctemplate := C.CString(template)
	defer C.free(unsafe.Pointer(ctemplate))
	if args != nil {
		cargs := makeArgs(args)
		defer freeArgs(cargs)
		return bool(C.lxc_container_create(lxc.container, ctemplate, &cargs[0]))
	}
	return bool(C.lxc_container_create(lxc.container, ctemplate, nil))
}

// Starts the container
func (lxc *Container) Start(useinit bool, args []string) bool {
	lxc.Lock()
	defer lxc.Unlock()

	cuseinit := 0
	if useinit {
		cuseinit = 1
	}
	if args != nil {
		cargs := makeArgs(args)
		defer freeArgs(cargs)
		return bool(C.lxc_container_start(lxc.container, C.int(cuseinit), &cargs[0]))
	}
	return bool(C.lxc_container_start(lxc.container, C.int(cuseinit), nil))
}

// Stops the container
func (lxc *Container) Stop() bool {
	lxc.Lock()
	defer lxc.Unlock()
	return bool(C.lxc_container_stop(lxc.container))
}

// Shutdowns the container
func (lxc *Container) Shutdown(timeout int) bool {
	lxc.Lock()
	defer lxc.Unlock()
	return bool(C.lxc_container_shutdown(lxc.container, C.int(timeout)))
}

// Destroys the container
func (lxc *Container) Destroy() bool {
	lxc.Lock()
	defer lxc.Unlock()
	return bool(C.lxc_container_destroy(lxc.container))
}

// Waits till the container changes its state or timeouts
func (lxc *Container) Wait(state State, timeout int) bool {
	lxc.Lock()
	defer lxc.Unlock()
	cstate := C.CString(state.String())
	defer C.free(unsafe.Pointer(cstate))
	return bool(C.lxc_container_wait(lxc.container, cstate, C.int(timeout)))
}

// Returns the container's configuration file's name
func (lxc *Container) ConfigFileName() string {
	lxc.RLock()
	defer lxc.RUnlock()

	// allocated in lxc.c
	configFileName := C.lxc_container_config_file_name(lxc.container)
	defer C.free(unsafe.Pointer(configFileName))

	return C.GoString(configFileName)
}

// Returns the value of the given key
func (lxc *Container) ConfigItem(key string) []string {
	lxc.RLock()
	defer lxc.RUnlock()

	ckey := C.CString(key)
	defer C.free(unsafe.Pointer(ckey))

	// allocated in lxc.c
	configItem := C.lxc_container_get_config_item(lxc.container, ckey)
	defer C.free(unsafe.Pointer(configItem))

	ret := strings.TrimSpace(C.GoString(configItem))
	return strings.Split(ret, "\n")
}

// Sets the value of given key
func (lxc *Container) SetConfigItem(key string, value string) bool {
	lxc.Lock()
	defer lxc.Unlock()
	ckey := C.CString(key)
	defer C.free(unsafe.Pointer(ckey))
	cvalue := C.CString(value)
	defer C.free(unsafe.Pointer(cvalue))
	return bool(C.lxc_container_set_config_item(lxc.container, ckey, cvalue))
}

// Returns the value of the given key
func (lxc *Container) CgroupItem(key string) []string {
	lxc.RLock()
	defer lxc.RUnlock()

	ckey := C.CString(key)
	defer C.free(unsafe.Pointer(ckey))

	// allocated in lxc.c
	cgroupItem := C.lxc_container_get_cgroup_item(lxc.container, ckey)
	defer C.free(unsafe.Pointer(cgroupItem))

	ret := strings.TrimSpace(C.GoString(cgroupItem))
	return strings.Split(ret, "\n")
}

// Sets the value of given key
func (lxc *Container) SetCgroupItem(key string, value string) bool {
	lxc.Lock()
	defer lxc.Unlock()
	ckey := C.CString(key)
	defer C.free(unsafe.Pointer(ckey))
	cvalue := C.CString(value)
	defer C.free(unsafe.Pointer(cvalue))
	return bool(C.lxc_container_set_cgroup_item(lxc.container, ckey, cvalue))
}

// Clears the value of given key
func (lxc *Container) ClearConfigItem(key string) bool {
	lxc.Lock()
	defer lxc.Unlock()
	ckey := C.CString(key)
	defer C.free(unsafe.Pointer(ckey))
	return bool(C.lxc_container_clear_config_item(lxc.container, ckey))
}

// Returns the keys
func (lxc *Container) Keys(key string) []string {
	lxc.RLock()
	defer lxc.RUnlock()

	ckey := C.CString(key)
	defer C.free(unsafe.Pointer(ckey))

	// allocated in lxc.c
	keys := C.lxc_container_get_keys(lxc.container, ckey)
	defer C.free(unsafe.Pointer(keys))

	ret := strings.TrimSpace(C.GoString(keys))
	return strings.Split(ret, "\n")
}

// Loads the configuration file from given path
func (lxc *Container) LoadConfigFile(path string) bool {
	lxc.Lock()
	defer lxc.Unlock()
	cpath := C.CString(path)
	defer C.free(unsafe.Pointer(cpath))
	return bool(C.lxc_container_load_config(lxc.container, cpath))
}

// Saves the configuration file to given path
func (lxc *Container) SaveConfigFile(path string) bool {
	lxc.Lock()
	defer lxc.Unlock()
	cpath := C.CString(path)
	defer C.free(unsafe.Pointer(cpath))
	return bool(C.lxc_container_save_config(lxc.container, cpath))
}

// Returns the configuration file's path
func (lxc *Container) ConfigPath() string {
	lxc.RLock()
	defer lxc.RUnlock()
	return C.GoString(C.lxc_container_get_config_path(lxc.container))
}

// Sets the configuration file's path
func (lxc *Container) SetConfigPath(path string) bool {
	lxc.Lock()
	defer lxc.Unlock()
	cpath := C.CString(path)
	defer C.free(unsafe.Pointer(cpath))
	return bool(C.lxc_container_set_config_path(lxc.container, cpath))
}

func (lxc *Container) NumberOfNetworkInterfaces() int {
	lxc.RLock()
	defer lxc.RUnlock()
	if lxc.Running() {
		return len(lxc.ConfigItem("lxc.network"))
	}
	return -1
}

func (lxc *Container) MemoryUsageInBytes() (ByteSize, error) {
	lxc.RLock()
	defer lxc.RUnlock()
	if lxc.Running() {
		memUsed, err := strconv.ParseFloat(lxc.CgroupItem("memory.usage_in_bytes")[0], 64)
		if err != nil {
			return -1, err
		}
		return ByteSize(memUsed), err
	}
	return -1, nil
}

func (lxc *Container) SwapUsageInBytes() (ByteSize, error) {
	lxc.RLock()
	defer lxc.RUnlock()
	if lxc.Running() {
		swapUsed, err := strconv.ParseFloat(lxc.CgroupItem("memory.memsw.usage_in_bytes")[0], 64)
		if err != nil {
			return -1, err
		}
		return ByteSize(swapUsed), err
	}
	return -1, nil
}

func (lxc *Container) MemoryLimitInBytes() (ByteSize, error) {
	lxc.RLock()
	defer lxc.RUnlock()
	if lxc.Running() {
		memLimit, err := strconv.ParseFloat(lxc.CgroupItem("memory.limit_in_bytes")[0], 64)
		if err != nil {
			return -1, err
		}
		return ByteSize(memLimit), err
	}
	return -1, nil
}

func (lxc *Container) SwapLimitInBytes() (ByteSize, error) {
	lxc.RLock()
	defer lxc.RUnlock()
	if lxc.Running() {
		swapLimit, err := strconv.ParseFloat(lxc.CgroupItem("memory.memsw.limit_in_bytes")[0], 64)
		if err != nil {
			return -1, err
		}
		return ByteSize(swapLimit), err
	}
	return -1, nil
}

// Returns the total CPU time (in nanoseconds) consumed by all tasks in this cgroup (including tasks lower in the hierarchy).
func (lxc *Container) CPUTime() (time.Duration, error) {
	lxc.RLock()
	defer lxc.RUnlock()
	if lxc.Running() {
		cpuUsage, err := strconv.ParseInt(lxc.CgroupItem("cpuacct.usage")[0], 10, 64)
		if err != nil {
			return -1, err
		}
		return time.Duration(cpuUsage), err
	}
	return -1, nil
}

// Returns the CPU time (in nanoseconds) consumed on each CPU by all tasks in this cgroup (including tasks lower in the hierarchy).
func (lxc *Container) CPUTimePerCPU() ([]time.Duration, error) {
	lxc.RLock()
	defer lxc.RUnlock()
	var cpuTimes []time.Duration

	if lxc.Running() {
		for _, v := range strings.Split(lxc.CgroupItem("cpuacct.usage_percpu")[0], " ") {
			cpuUsage, err := strconv.ParseInt(v, 10, 64)
			if err != nil {
				return nil, err
			}
			cpuTimes = append(cpuTimes, time.Duration(cpuUsage))
		}
		return cpuTimes, nil
	}
	return nil, nil
}

// Returns the number of CPU cycles (in the units defined by USER_HZ on the system) consumed by tasks in this cgroup and its children in both user mode and system (kernel) mode.
func (lxc *Container) CPUStats() ([]int64, error) {
	lxc.RLock()
	defer lxc.RUnlock()
	if lxc.Running() {
		cpuStat := lxc.CgroupItem("cpuacct.stat")
		user, _ := strconv.ParseInt(strings.Split(cpuStat[0], " ")[1], 10, 64)
		system, _ := strconv.ParseInt(strings.Split(cpuStat[1], " ")[1], 10, 64)
		return []int64{user, system}, nil
	}
	return nil, nil
}
