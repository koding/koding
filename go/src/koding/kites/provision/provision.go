package main

import (
	"errors"
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/virt"
)

type Provision struct {
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
		"vm.start":        Provision.Start,
		"vm.shutdown":     Provision.Shutdown,
		"vm.stop":         Provision.Stop,
		"vm.reinitialize": Provision.Reinitialize,
		"vm.info":         Provision.Info,
	}

	k := kite.New(o, new(Provision), methods)
	k.Start()
}

func getVos(username, hostname string) (*virt.VOS, error) {
	if username == "" || hostname == "" {
		return nil, errors.New("username or hostname is empty")
	}

	u, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, err
	}

	user := virt.User(*u)

	v, err := modelhelper.GetVM(hostname)
	if err != nil {
		return nil, err
	}

	vm := virt.VM(v)
	return vm.OS(&user)
}

func (Provision) Start(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	if err := vos.VM.Start(); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) Stop(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	if err := vos.VM.Stop(); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) Shutdown(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	if err := vos.VM.Shutdown(); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) Info(r *protocol.KiteDnodeRequest, result *bool) error {
	//TODO: implement this
	// info := channel.KiteData.(*VMInfo)
	// info.State = getState(name)

	*result = true
	return nil
}

func (Provision) Reinitialize(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	logWarning := func(msg string, args ...interface{}) {
		fmt.Printf(msg, args)
	}

	vos.VM.Prepare(true, logWarning)
	if err := vos.VM.Start(); err != nil {
		return err
	}

	*result = true
	return nil
}

/*

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
*/
