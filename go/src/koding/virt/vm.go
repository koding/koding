package virt

import (
	"fmt"
	"net"
	"os"
	"os/user"
	"strconv"
	"text/template"
)

type VM struct {
	IP  net.IP
	MAC net.HardwareAddr
}

func FromIP(a, b, c, d byte) (*VM, error) {
	if a != 10 || b == 0 {
		return nil, fmt.Errorf("Illegal VM address: %d.%d.%d.%d", a, b, c, d)
	}
	return &VM{
		IP:  net.IPv4(a, b, c, d),
		MAC: net.HardwareAddr([]byte{0, 0, a, b, c, d}),
	}, nil
}

func FromUid(uid int) (*VM, error) {
	return FromIP(10, byte(uid>>24), byte(uid>>16), byte(uid>>8))
}

func FromUsername(username string) (*VM, error) {
	u, err := user.Lookup(username)
	if err != nil {
		return nil, err
	}
	uid, err := strconv.Atoi(u.Uid)
	if err != nil {
		return nil, err
	}
	return FromUid(uid)
}

func (vm *VM) String() string {
	return vm.IP.String()
}

func (vm *VM) Uid() int {
	return int(vm.IP[13])<<24 + int(vm.IP[14])<<16 + int(vm.IP[15])<<8
}

func (vm *VM) Username() string {
	u, err := user.LookupId(strconv.Itoa(vm.Uid()))
	if err != nil {
		return "nobody"
	}
	return u.Username
}

func (vm *VM) Hostname() string {
	return "koding-" + vm.Username()
}

var templates *template.Template

func init() {
	var err error
	templates, err = template.ParseGlob("templates/lxc/*")
	if err != nil {
		panic(err)
	}
}

func (vm *VM) Setup() {
	vm.GenerateFile("config", false)
	vm.GenerateFile("pre-start", true)
	vm.GenerateFile("post-stop", true)
	vm.GenerateFile("fstab", false)
}

func (vm *VM) GenerateFile(name string, executable bool) {
	file, err := os.Create(fmt.Sprintf("/var/lib/lxc/%s/%s", vm, name))
	if err != nil {
		panic(err)
	}
	defer file.Close()

	err = templates.ExecuteTemplate(file, name, vm)
	if err != nil {
		panic(err)
	}

	if executable {
		file.Chmod(0755)
	} else {
		file.Chmod(0644)
	}
}
