package main

import (
	"bytes"
	"fmt"
	"koding/tools/db"
	"labix.org/v2/mgo/bson"
	"os"
	"os/exec"
	"strings"
)

func main() {
	list, err := exec.Command("/usr/bin/rbd", "ls", "--pool", "vms").Output()
	if err != nil {
		panic(err)
	}

	skipped := 0
	for _, name := range strings.Split(string(list[:len(list)-1]), "\n") {
		if bson.IsObjectIdHex(name[3:]) {
			if !migrate(name) {
				skipped += 1
			}
		}
	}

	fmt.Printf("%d skipped.\n", skipped)
	if skipped != 0 {
		os.Exit(1)
	}
}

func migrate(name string) bool {
	info, err := exec.Command("/usr/bin/rbd", "info", "--pool", "vms", "--image", name).Output()
	if err != nil {
		fmt.Println(err)
		return false
	}

	if !bytes.Contains(info, []byte("format: 2")) {
		return true
	}

	if err := db.VMs.Update(bson.M{"_id": bson.ObjectIdHex(name[3:]), "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": "migration"}}); err != nil {
		fmt.Println("Could not lock " + name + " in DB. Skipping.")
		return false
	}
	defer db.VMs.Update(bson.M{"_id": bson.ObjectIdHex(name[3:])}, bson.M{"$set": bson.M{"hostKite": nil}})

	fmt.Println("Migrating " + name + "...")

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

	fmt.Println("Done.")
	return true
}
