package main

import (
	"fmt"
	"koding/db/mongodb"
	"koding/kites/kloud/provider/koding"
	"os"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/multiconfig"
)

type Config struct {
	Username string `required:"true"`
	MongoURL string
}

func main() {
	if err := realMain(); err != nil {
		fmt.Fprint(os.Stderr, err.Error())
		os.Exit(1)
	}

	os.Exit(0)
}

func realMain() error {
	conf := new(Config)
	multiconfig.MustLoad(conf)

	db := mongodb.NewMongoDB(conf.MongoURL)

	var machine *koding.MachineDocument
	if err := db.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"credential": conf.Username}).One(&machine)
	}); err != nil {
		return err
	}

	fmt.Printf("machine = %+v\n", machine)
	return nil
}
