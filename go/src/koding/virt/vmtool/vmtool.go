package main

import (
	"bufio"
	"fmt"
	"io"
	"io/ioutil"
	"koding/db/models"
	"koding/tools/utils"
	"koding/virt"
	"log"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/jessevdk/go-flags"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	usage = `usage: <action> [<vm-id>|all]

	list
	start
	shutdown
	stop
	ip
	unprepare
	create-test-vms
	rbd-orphans
`
)

var flagOpts struct {
	Templates string `long:"templates" short:"t" description:"Change template dir." default:"files/templates"`
}

func main() {
	remainingArgs, err := flags.Parse(&flagOpts)
	if err != nil {
		log.Fatal(err)
	}

	if err := virt.LoadTemplates(flagOpts.Templates); err != nil {
		log.Fatal(err)
	}

	if len(remainingArgs) == 0 {
		fmt.Fprintf(os.Stderr, usage)
		os.Exit(0)
	}

	action := remainingArgs[0]
	actionArgs := remainingArgs[1:]

	fn := actions[action]
	fn(actionArgs)
}

var actions = map[string]func(args []string){
	"list": func(args []string) {
		dirs, err := ioutil.ReadDir("/var/lib/lxc")
		if err != nil {
			log.Println(err)
			return
		}

		for _, dir := range dirs {
			if strings.HasPrefix(dir.Name(), "vm-") {
				fmt.Println(dir.Name())
			}
		}

	},

	"start": func(args []string) {
		for _, vm := range selectVMs(args[0]) {
			err := vm.Start()
			fmt.Printf("%v: %v\n%s", vm, err)
		}
	},

	"shutdown": func(args []string) {
		for _, vm := range selectVMs(args[0]) {
			err := vm.Shutdown()
			fmt.Printf("%v: %v\n%s", vm, err)
		}
	},

	"stop": func(args []string) {
		for _, vm := range selectVMs(args[0]) {
			err := vm.Stop()
			fmt.Printf("%v: %v\n%s", vm, err)
		}
	},

	"unprepare": func(args []string) {
		for _, vm := range selectVMs(args[0]) {
			err := vm.Unprepare()
			fmt.Printf("%v: %v\n", vm, err)
		}
	},

	"ip": func(args []string) {
		if len(args) != 2 {
			log.Fatal("usage: ip <mongo-url> <vm-id>")
		}

		session, err := mgo.Dial(args[0])
		if err != nil {
			panic(err)
		}

		vm := new(models.VM)
		session.SetSafe(&mgo.Safe{})

		vmId := strings.TrimPrefix(args[1], "vm-")

		database := session.DB("")
		err = database.C("jVMs").Find(bson.M{"_id": bson.ObjectIdHex(vmId)}).One(vm)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		fmt.Println(vm.IP.String())
	},

	"create-test-vms": func(args []string) {
		startIP := net.IPv4(10, 128, 2, 7)
		if len(os.Args) >= 4 {
			startIP = net.ParseIP(os.Args[3])
		}
		ipPoolFetch, _ := utils.NewIntPool(utils.IPToInt(startIP), nil)
		count, _ := strconv.Atoi(args[0])

		done := make(chan string)
		for i := 0; i < count; i++ {
			go func(i int) {
				vm := virt.VM{
					Id: bson.NewObjectId(),
					IP: utils.IntToIP(<-ipPoolFetch),
				}
				vm.ApplyDefaults()
				fmt.Println(i, "preparing...")
				for _ = range vm.Prepare(false) {
				}

				fmt.Println(i, "starting...")
				if err := vm.Start(); err != nil {
					log.Println(i, "start", err)
				}

				// wait until network is up
				fmt.Println(i, "waiting...")
				if err := vm.WaitForNetwork(time.Second * 5); err != nil {
					log.Print(i, "WaitForNetwork", err)
				}
				done <- fmt.Sprintln(i, "ready", "vm-"+vm.Id.Hex())
			}(i)
		}

		for i := 0; i < count; i++ {
			fmt.Println(<-done)
		}
	},

	"rbd-orphans": func(args []string) {
		if len(args) == 0 {
			log.Fatal("usage: vmtool rbd-orphans <mongo-url>")
		}

		session, err := mgo.Dial(args[0])
		if err != nil {
			panic(err)
		}
		session.SetSafe(&mgo.Safe{})
		database := session.DB("")
		iter := database.C("jVMs").Find(bson.M{}).Select(bson.M{"_id": 1}).Iter()
		var vm struct {
			Id bson.ObjectId `bson:"_id"`
		}
		ids := make(map[string]bool)
		for iter.Next(&vm) {
			ids["vm-"+vm.Id.Hex()] = true
		}
		if err := iter.Close(); err != nil {
			panic(err)
		}

		cmd := exec.Command("/usr/bin/rbd", "ls", "--pool", "vms")
		pipe, _ := cmd.StdoutPipe()
		r := bufio.NewReader(pipe)
		if err := cmd.Start(); err != nil {
			panic(err)
		}
		fmt.Println("RBD images without corresponding database entry:")
		for {
			image, err := r.ReadString('\n')
			if err != nil {
				if err != io.EOF {
					panic(err)
				}
				break
			}
			image = image[:len(image)-1]

			if !ids[image] {
				fmt.Println(image)
			}
		}
	},
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

	if strings.HasPrefix(selector, "vm-") {
		_, err := os.Stat("/var/lib/lxc/" + selector)
		if err != nil {
			if !os.IsNotExist(err) {
				panic(err)
			}
			fmt.Println("No prepared VM with name: " + selector)
			os.Exit(1)
		}
		return []*virt.VM{&virt.VM{Id: bson.ObjectIdHex(selector[3:])}}
	}

	fmt.Println("Invalid selector: " + selector)
	os.Exit(1)
	return nil
}
