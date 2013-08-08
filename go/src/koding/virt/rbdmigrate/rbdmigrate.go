package main

import (
	"bytes"
	"fmt"
	"koding/tools/db"
	"labix.org/v2/mgo/bson"
	"os"
	"os/exec"
)

func main() {
	if _, err := db.VMs.UpdateAll(bson.M{"hostKite": "migration"}, bson.M{"$set": bson.M{"hostKite": nil}}); err != nil { // ensure that really all are set to nil
		panic(err)
	}

	var vm struct {
		Id bson.ObjectId `bson:"_id"`
	}
	iter := db.VMs.Find(bson.M{"webHome": bson.M{"$not": bson.RegEx{Pattern: "^guest-"}}}).Select(bson.M{"_id": 1}).Iter()
	queue := make([]string, 0)
	for iter.Next(&vm) {
		info, _ := exec.Command("/usr/bin/rbd", "info", "--pool", "vms", "--image", "vm-"+vm.Id.Hex()).Output()
		if bytes.Contains(info, []byte("format: 2")) {
			queue = append(queue, "vm-"+vm.Id.Hex())
		}
	}
	if err := iter.Close(); err != nil {
		panic(err)
	}

	skipped := 0
	for i, name := range queue {
		fmt.Printf("Migrating %s (%d/%d)...\n", i+1, len(queue), name)
		if !migrate(name) {
			skipped += 1
		}
	}

	fmt.Printf("%d skipped.\n", skipped)
	if skipped != 0 {
		os.Exit(1)
	}
}

func migrate(name string) bool {
	if err := db.VMs.Update(bson.M{"_id": bson.ObjectIdHex(name[3:]), "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": "migration"}}); err != nil {
		fmt.Println("Could not lock in DB. Skipping.")
		return false
	}
	defer db.VMs.Update(bson.M{"_id": bson.ObjectIdHex(name[3:])}, bson.M{"$set": bson.M{"hostKite": nil}})

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

	fmt.Println("Migration complete.")
	return true
}
