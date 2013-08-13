package main

import (
	"bytes"
	"fmt"
	"koding/tools/db"
	"labix.org/v2/mgo/bson"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
)

func main() {
	abort := false
	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigtermChannel
		abort = true
	}()

	if _, err := db.VMs.UpdateAll(bson.M{"hostKite": "migration"}, bson.M{"$set": bson.M{"hostKite": nil}}); err != nil { // ensure that really all are set to nil
		panic(err)
	}

	var vm struct {
		Id        bson.ObjectId `bson:"_id"`
		RbdFormat int           `bson:"rbdFormat"`
	}

	query := db.VMs.Find(bson.M{"hostnameAlias": bson.M{"$not": bson.RegEx{Pattern: "guest-"}}, "rbdFormat": nil}).Select(bson.M{"_id": 1, "rbdFormat": 1})
	count, _ := query.Count()
	iter := query.Iter()
	i := 0
	for iter.Next(&vm) && !abort {
		i += 1
		fmt.Printf("Checking %d/%d: vm-%s\n", i, count, vm.Id.Hex())
		info, _ := exec.Command("/usr/bin/rbd", "info", "--pool", "vms", "--image", "vm-"+vm.Id.Hex()).Output()

		if bytes.Contains(info, []byte("format: 1")) {
			if err := db.VMs.UpdateId(vm.Id, bson.M{"$set": bson.M{"rbdFormat": 1}}); err != nil {
				fmt.Println(err)
			}
		}
		if bytes.Contains(info, []byte("format: 2")) {
			if err := db.VMs.UpdateId(vm.Id, bson.M{"$set": bson.M{"rbdFormat": 2}}); err != nil {
				fmt.Println(err)
			}
		}
	}
	if err := iter.Close(); err != nil {
		panic(err)
	}

	query = db.VMs.Find(bson.M{"hostnameAlias": bson.M{"$not": bson.RegEx{Pattern: "guest-"}}, "rbdFormat": 2}).Select(bson.M{"_id": 1, "rbdFormat": 1})
	count, _ = query.Count()
	iter = query.Iter()
	i = 0
	skipped := 0
	for iter.Next(&vm) && !abort {
		i += 1
		fmt.Printf("Migrating %d/%d: vm-%s\n", vm.Id.Hex(), i+1, count)
		if !migrate(vm.Id) {
			skipped += 1
		}
	}
	if err := iter.Close(); err != nil {
		panic(err)
	}

	fmt.Printf("%d skipped.\n", skipped)
	if skipped != 0 || abort {
		os.Exit(1)
	}
}

func migrate(id bson.ObjectId) bool {
	if err := db.VMs.Update(bson.M{"_id": id, "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": "migration"}}); err != nil {
		fmt.Println("Could not lock in DB. Skipping.")
		return false
	}
	defer db.VMs.UpdateId(id, bson.M{"$set": bson.M{"hostKite": nil}})

	name := "vm-" + id.Hex()

	cmd := exec.Command("/usr/bin/rbd", "map", "--pool", "vms", "--image", name)
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Println(err)
		return false
	}

	cmd = exec.Command("/usr/bin/rbd", "import", "--pool", "vms", "--image", name+"-format-1", "--path", "/dev/rbd/vms/"+name, "--image-format", "1")
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Println(err)
		return false
	}

	cmd = exec.Command("/usr/bin/rbd", "unmap", "/dev/rbd/vms/"+name)
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Println(err)
		return false
	}

	cmd = exec.Command("/usr/bin/rbd", "mv", "--pool", "vms", "--image", name, "--dest-pool", "vms", "--dest", name+"-format-2")
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Println(err)
		return false
	}

	cmd = exec.Command("/usr/bin/rbd", "mv", "--pool", "vms", "--image", name+"-format-1", "--dest-pool", "vms", "--dest", name)
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Println(err)
		return false
	}

	if err := db.VMs.UpdateId(id, bson.M{"$set": bson.M{"rbdFormat": 1}}); err != nil {
		fmt.Println(err)
	}
	fmt.Println("Migration complete.")
	return true
}
