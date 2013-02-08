package main

import (
	"fmt"
	"io/ioutil"
	"koding/tools/utils"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"runtime"
	"strconv"
	"strings"
)

var actions = map[string]func(){
	"start": func() {
		for _, vm := range selectVMs(os.Args[2]) {
			out, err := vm.StartCommand().CombinedOutput()
			fmt.Printf("%v: %v\n%s", vm, err, string(out))
		}
	},
	"shutdown": func() {
		for _, vm := range selectVMs(os.Args[2]) {
			out, err := vm.ShutdownCommand().CombinedOutput()
			fmt.Printf("%v: %v\n%s", vm, err, string(out))
		}
	},
	"stop": func() {
		for _, vm := range selectVMs(os.Args[2]) {
			out, err := vm.StopCommand().CombinedOutput()
			fmt.Printf("%v: %v\n%s", vm, err, string(out))
		}
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
				done <- i
			}(i)
		}
		for i := 0; i < count; i++ {
			fmt.Println(<-done)
		}
	},
}

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
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
