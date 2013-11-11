// Copyright (c) 2012 VMware, Inc.

package sigar

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

func TestLoadAverage(t *testing.T) {
	avg := LoadAverage{}
	if err := avg.Get(); err != nil {
		t.Error(err)
	}
}

func TestUptime(t *testing.T) {
	uptime := Uptime{}
	if err := uptime.Get(); err != nil {
		t.Error(err)
	}
	if uptime.Length <= 0 {
		t.Errorf("Invalid uptime.Length=%d", uptime.Length)
	}
}

func TestMem(t *testing.T) {
	mem := Mem{}
	err := mem.Get()
	if err != nil {
		t.Error(err)
	}
	if mem.Total <= 0 {
		t.Errorf("Invalid mem.Total=%d", mem.Total)
	}

	if (mem.Used + mem.Free) > mem.Total {
		t.Errorf("Invalid mem.Used=%d or mem.Free=%d",
			mem.Used, mem.Free)
	}
}

func TestSwap(t *testing.T) {
	swap := Swap{}
	err := swap.Get()
	if err != nil {
		t.Error(err)
	}
	if (swap.Used + swap.Free) > swap.Total {
		t.Errorf("Invalid swap.Used=%d or swap.Free=%d",
			swap.Used, swap.Free)
	}
}

func TestCpu(t *testing.T) {
	cpu := Cpu{}
	err := cpu.Get()
	if err != nil {
		t.Error(err)
	}
}

func TestCpuList(t *testing.T) {
	cpulist := CpuList{}
	err := cpulist.Get()
	if err != nil {
		t.Error(err)
	}
	nsigar := len(cpulist.List)
	numcpu := runtime.NumCPU()
	if nsigar != numcpu {
		t.Errorf("CpuList num mismatch: sigar=%d, runtime=%d",
			nsigar, numcpu)
	}
}

func TestFileSystemList(t *testing.T) {
	fslist := FileSystemList{}
	err := fslist.Get()
	if err != nil {
		t.Error(err)
	}

	if len(fslist.List) <= 0 {
		t.Error("Empty FileSystemList")
	}
}

func TestFileSystemUsage(t *testing.T) {
	fsusage := FileSystemUsage{}
	err := fsusage.Get("/")
	if err != nil {
		t.Error(err)
	}

	err = fsusage.Get("T O T A L L Y B O G U S")
	if err == nil {
		t.Error("FileSystemUsage.Get should have failed")
	}
}

func TestProcList(t *testing.T) {
	pids := ProcList{}
	err := pids.Get()
	if err != nil {
		t.Error(err)
	}

	if len(pids.List) <= 2 {
		t.Errorf("invalid ProcList %v", pids)
	}

	err = pids.Get()
	if err != nil {
		t.Error(err)
	}
}

const invalidPid = 666666

func TestProcState(t *testing.T) {
	state := ProcState{}
	err := state.Get(os.Getppid())
	if err != nil {
		t.Error(err)
	}

	if state.State != RunStateRun && state.State != RunStateSleep {
		t.Error("Invalid ProcState.State '%v'", state.State)
	}

	if state.Name != "go" { // our parent is "go test"
		t.Error("Invalid ProcState.Name '%v'", state.Name)
	}

	err = state.Get(invalidPid)
	if err == nil {
		t.Error("Invalid ProcState.Get('%d')", invalidPid)
	}
}

func TestProcMem(t *testing.T) {
	mem := ProcMem{}
	err := mem.Get(os.Getppid())
	if err != nil {
		t.Error(err)
	}

	err = mem.Get(invalidPid)
	if err == nil {
		t.Error("Invalid ProcMem.Get('%d')", invalidPid)
	}
}

func TestProcTime(t *testing.T) {
	time := ProcTime{}
	err := time.Get(os.Getppid())
	if err != nil {
		t.Error(err)
	}

	err = time.Get(invalidPid)
	if err == nil {
		t.Error("Invalid ProcTime.Get('%d')", invalidPid)
	}
}

func TestProcArgs(t *testing.T) {
	args := ProcArgs{}
	err := args.Get(os.Getppid())
	if err != nil {
		t.Error(err)
	}

	if len(args.List) < 2 {
		t.Errorf("invalid ProcArgs %s", args.List)
	}
}

func TestProcExe(t *testing.T) {
	exe := ProcExe{}
	err := exe.Get(os.Getppid())
	if err != nil {
		t.Error(err)
	}

	if filepath.Base(exe.Name) != "go" {
		t.Errorf("Invalid ProcExe.Name '%v'", exe.Name)
	}
}
