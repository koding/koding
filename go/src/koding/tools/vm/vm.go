package vm

import (
	"fmt"
	"net"
	"os"
	"text/template"
)

type VM struct {
	IP   net.IP
	MAC  net.HardwareAddr
	User string
}

func Get(a, b, c, d byte) *VM {
	if a != 10 || b == 0 {
		panic("Illegal VM address.")
	}
	return &VM{
		IP:   net.IPv4(a, b, c, d),
		MAC:  net.HardwareAddr([]byte{0, 0, a, b, c, d}),
		User: "neelance",
	}
}

func (vm *VM) String() string {
	return vm.IP.String()
}

func (vm *VM) Hostname() string {
	return "koding-" + vm.User
}

var templates *template.Template

func init() {
	var err error
	templates, err = template.ParseGlob("templates/lxc/*")
	if err != nil {
		panic(err)
	}
}

func (vm *VM) WriteConfig() {
	vm.GenerateFile("config", false)
	vm.GenerateFile("pre-start", true)
	vm.GenerateFile("post-stop", true)
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
