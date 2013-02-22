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
	"sort"
	"strconv"
	"strings"
)

type PackageWithCount struct {
	pkg   string
	count int
}

type PackageWithCountSlice []PackageWithCount

func (s PackageWithCountSlice) Len() int {
	return len(s)
}

func (s PackageWithCountSlice) Less(i, j int) bool {
	return s[i].count > s[j].count
}

func (s PackageWithCountSlice) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

var actions = map[string]func(){
	"start": func() {
		for _, vm := range selectVMs(os.Args[2]) {
			out, err := vm.Start()
			fmt.Printf("%v: %v\n%s", vm, err, string(out))
		}
	},
	"shutdown": func() {
		for _, vm := range selectVMs(os.Args[2]) {
			out, err := vm.Shutdown()
			fmt.Printf("%v: %v\n%s", vm, err, string(out))
		}
	},
	"stop": func() {
		for _, vm := range selectVMs(os.Args[2]) {
			out, err := vm.Stop()
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
				vm.Prepare(nil, false)
				done <- i
			}(i)
		}
		for i := 0; i < count; i++ {
			fmt.Println(<-done)
		}
	},
	"dpkg-statistics": func() {
		entries, err := ioutil.ReadDir("/var/lib/lxc/dpkg-statuses")
		if err != nil {
			panic(err)
		}

		counts := make(map[string]int)
		for _, entry := range entries {
			packages, err := virt.ReadDpkgStatus("/var/lib/lxc/dpkg-statuses/" + entry.Name())
			if err != nil {
				panic(err)
			}
			for pkg := range packages {
				counts[pkg] += 1
			}
		}

		packages, err := virt.ReadDpkgStatus("/var/lib/lxc/vmroot/rootfs/var/lib/dpkg/status")
		if err != nil {
			panic(err)
		}
		for pkg := range packages {
			delete(counts, pkg)
		}

		list := make(PackageWithCountSlice, 0, len(counts))
		for pkg, count := range counts {
			list = append(list, PackageWithCount{pkg, count})
		}
		sort.Sort(list)

		fmt.Println("Top 10 installed packages not in vmroot:")
		for i, entry := range list {
			if i == 10 {
				break
			}
			fmt.Printf("%s: %d\n", entry.pkg, entry.count)
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
