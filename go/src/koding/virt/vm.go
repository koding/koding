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

var templates *template.Template

func init() {
	var err error
	templates, err = template.ParseGlob("templates/lxc/*")
	if err != nil {
		panic(err)
	}
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

func (vm *VM) File(path string) string {
	return fmt.Sprintf("/var/lib/lxc/%s/%s", vm, path)
}

func (vm *VM) Prepare() {
	// create directories
	vm.MkdirAll("", false)
	vm.MkdirAll("overlayfs-upperdir/etc", true)
	vm.MkdirAll("rootfs", true)

	// write LXC files
	vm.GenerateFile("config", false)
	vm.GenerateFile("pre-start", true)
	vm.GenerateFile("post-stop", true)
	vm.GenerateFile("fstab", false)

	// write hostname file
	hostname, err := os.Open(vm.File("overlayfs-upperdir/etc/hostname"))
	if err != nil {
		panic(err)
	}
	hostname.Write([]byte(vm.Username() + ".koding.com"))
	hostname.Close()

	// write passwd file
	passwdFile := fmt.Sprintf(vm.File("overlayfs-upperdir/etc/passwd"))
	users, _ := ReadPasswd(passwdFile) // error ignored

	lowerUsers, err := ReadPasswd("/var/lib/lxc/vmroot/rootfs/etc/passwd")
	if err != nil {
		panic(err)
	}
	for uid, user := range lowerUsers {
		users[uid] = user
	}

	users[1000] = &User{vm.Username(), 1000, "", "/home/" + vm.Username(), "/bin/bash"}
	err = WritePasswd(users, passwdFile)
	if err != nil {
		panic(err)
	}

	// write group file
	groupFile := fmt.Sprintf(vm.File("overlayfs-upperdir/etc/group"))
	groups, _ := ReadGroup(groupFile) // error ignored

	lowerGroups, err := ReadGroup("/var/lib/lxc/vmroot/rootfs/etc/group")
	if err != nil {
		panic(err)
	}
	for gid, group := range lowerGroups {
		if groups[gid] != nil {
			for user := range groups[gid].Users {
				group.Users[user] = true
			}
		}
		if group.Name == "sudo" {
			group.Users[vm.Username()] = true
		}
		groups[gid] = group
	}

	groups[1000] = &Group{vm.Username(), map[string]bool{vm.Username(): true}}
	err = WriteGroup(groups, groupFile)
	if err != nil {
		panic(err)
	}
}

func (vm *VM) MkdirAll(path string, chown bool) {
	fullPath := fmt.Sprintf("/var/lib/lxc/%s/%s", vm, path)
	os.MkdirAll(fullPath, 0755)
	if chown {
		os.Chown(fullPath, vm.Uid(), vm.Uid())
	}
}

func (vm *VM) GenerateFile(name string, executable bool) {
	file, err := os.Create(vm.File(name))
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
