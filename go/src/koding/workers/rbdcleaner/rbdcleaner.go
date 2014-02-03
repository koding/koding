package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func main() {

	vm := new(models.VM)
	allVMs := func(c *mgo.Collection) error {
		iter := c.Find(nil).Select(bson.M{"_id": 1}).Iter()
		for iter.Next(&vm) {
			fmt.Println("vm", vm.Id.String())
		}

		if err := iter.Close(); err != nil {
			return err
		}

		return nil
	}

	err := mongodb.Run("jVMs", allVMs)
	fmt.Println(err)
}
