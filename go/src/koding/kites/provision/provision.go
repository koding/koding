package main

import (
	"errors"
	"flag"
	"fmt"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"os/exec"
	"strings"
	"time"
)

type VM struct {
	ProgramName string
}

var (
	port = flag.String("port", "4000", "port to bind itself")
	ip   = flag.String("ip", "0.0.0.0", "ip to bind itself")
)

func main() {
	flag.Parse()
	o := &protocol.Options{
		LocalIP:  *ip,
		Username: "fatih",
		Kitename: "provision",
		Version:  "1",
		Port:     *port,
	}

	methods := map[string]interface{}{
		"vm.start":        VM.Start,
		"vm.shutdown":     VM.Shutdown,
		"vm.stop":         VM.Stop,
		"vm.reinitialize": VM.Reinitialize,
		"vm.info":         VM.Info,
	}

	k := kite.New(o, new(VM), methods)
	k.Start()
}

func (VM) Start(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Name string
	}

	if r.Args.Unmarshal(&params) != nil || params.Name == "" {
		return errors.New("{ path: [string] }")
	}

	if err := start(params.Name); err != nil {
		return err
	}

	*result = true
	return nil
}

func (VM) Stop(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Name string
	}

	if r.Args.Unmarshal(&params) != nil || params.Name == "" {
		return errors.New("{ path: [string] }")
	}

	if err := stop(params.Name); err != nil {
		return err
	}

	*result = true
	return nil
}

func (VM) Shutdown(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Name string
	}

	if r.Args.Unmarshal(&params) != nil || params.Name == "" {
		return errors.New("{ path: [string] }")
	}

	if err := shutdown(params.Name); err != nil {
		return err
	}

	*result = true
	return nil
}

func (VM) Info(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Name string
	}

	if r.Args.Unmarshal(&params) != nil || params.Name == "" {
		return errors.New("{ path: [string] }")
	}

	//TODO: implement this
	// info := channel.KiteData.(*VMInfo)
	// info.State = getState(name)

	*result = true
	return nil
}

func (VM) Reinitialize(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Name string
	}

	if r.Args.Unmarshal(&params) != nil || params.Name == "" {
		return errors.New("{ path: [string] }")
	}

	*result = true
	return nil
}

func start(name string) error {
	if name == "" {
		return errors.New("empty lxc name is passed")
	}

	if out, err := exec.Command("/usr/bin/lxc-start", "--name", name, "--daemon").CombinedOutput(); err != nil {
		return fmt.Errorf("[%s] lxc-start failed.", time.Now().Format(time.Stamp), err, out)
	}

	return waitForState(name, "RUNNING", time.Second)
}

func stop(name string) error {
	if out, err := exec.Command("/usr/bin/lxc-stop", "--name", name).CombinedOutput(); err != nil {
		return fmt.Errorf("[%s] lxc-stop failed.", time.Now().Format(time.Stamp), err, out)
	}
	return waitForState(name, "STOPPED", time.Second)
}

func shutdown(name string) error {
	if out, err := exec.Command("/usr/bin/lxc-shutdown", "--name", name).CombinedOutput(); err != nil {
		if getState(name) != "STOPPED" {
			return fmt.Errorf("[%s] lxc-shutdown failed.", time.Now().Format(time.Stamp), err, out)
		}
	}
	waitForState(name, "STOPPED", 5*time.Second) // may time out, then vm is force stopped
	return stop(name)
}

func getState(name string) string {
	out, err := exec.Command("/usr/bin/lxc-info", "--name", name, "--state").CombinedOutput()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out)[6:])
}

func waitForState(name, state string, timeout time.Duration) error {
	tryUntil := time.Now().Add(timeout)
	for getState(name) != state {
		if time.Now().After(tryUntil) {
			return errors.New("Timeout while waiting for VM state.")
		}
		time.Sleep(time.Second / 10)
	}
	return nil
}
