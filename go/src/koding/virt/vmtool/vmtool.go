package main

import (
	"fmt"
	"io/ioutil"
	"koding/tools/utils"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

var actions = map[string]func(){
	"shutdown": func() {
		withAll("lxc-shutdown")
	},
	"stop": func() {
		withAll("lxc-stop")
	},
	"unprepare": func() {
		for _, vm := range selectVMs(os.Args[2]) {
			err := vm.Unprepare()
			fmt.Printf("%v: %v\n", vm, err)
		}
	},
	"create-test-vms": func() {
		startIP := net.IPv4(172, 16, 0, 2)
		if len(os.Args) >= 4 {
			startIP = net.ParseIP(os.Args[3])
		}
		ipPoolFetch, _ := utils.NewIntPool(utils.IPToInt(startIP), nil)
		count, _ := strconv.Atoi(os.Args[2])
		done := make(chan int)
		for i := 0; i < count; i++ {
			go func(i int) {
				vm := virt.VM{
					Id: bson.NewObjectId(),
					IP: utils.IntToIP(<-ipPoolFetch),
				}
				vm.Prepare(nil)
				vm.StartCommand().Run()
				done <- i
			}(i)
		}
		for i := 0; i < count; i++ {
			fmt.Println(<-done)
		}
	},
}

func main() {
	virt.LoadTemplates("templates")
	action := actions[os.Args[1]]
	action()
}

func selectVMs(selector string) []*virt.VM {
	if selector == "all" {
		dirs, err := ioutil.ReadDir("/var/lib/lxc")
		if err != nil {
			panic(err)
		}
		vms := make([]*virt.VM, 0)
		for _, dir := range dirs {
			if strings.HasPrefix(dir.Name(), "vm-") {
				vms = append(vms, &virt.VM{Id: bson.ObjectIdHex(dir.Name()[3:])})
			}
		}
		return vms
	}
	fmt.Println("Invalid selector: " + selector)
	os.Exit(1)
	return nil
}

func withAll(action string) {
	for _, vm := range selectVMs(os.Args[2]) {
		cmd := exec.Command(action, "-n", vm.String())
		out, err := cmd.CombinedOutput()
		fmt.Println(strings.Join(cmd.Args, " ") + ":")
		fmt.Println(err)
		fmt.Println(string(out))
	}
}
