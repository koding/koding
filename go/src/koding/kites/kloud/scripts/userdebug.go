package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"os"
	"text/tabwriter"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/multiconfig"
)

type Config struct {
	Username string `required:"true"`
	MongoURL string
}

type MachineDocument struct {
	Id          bson.ObjectId `bson:"_id" json:"-"`
	Label       string        `bson:"label"`
	Domain      string        `bson:"domain"`
	QueryString string        `bson:"queryString"`
	IpAddress   string        `bson:"ipAddress"`
	Assignee    struct {
		InProgress bool      `bson:"inProgress"`
		AssignedAt time.Time `bson:"assignedAt"`
	} `bson:"assignee"`
	Status struct {
		State      string    `bson:"state"`
		Reason     string    `bson:"reason"`
		ModifiedAt time.Time `bson:"modifiedAt"`
	} `bson:"status"`
	Provider   string    `bson:"provider"`
	Credential string    `bson:"credential"`
	CreatedAt  time.Time `bson:"createdAt"`
	Meta       struct {
		AlwaysOn     bool   `bson:"alwaysOn"`
		InstanceId   string `bson:"instanceId"`
		InstanceType string `bson:"instance_type"`
		InstanceName string `bson:"instanceName"`
		Region       string `bson:"region"`
		StorageSize  int    `bson:"storage_size"`
		SourceAmi    string `bson:"source_ami"`
	} `bson:"meta"`
	Users  []models.Permissions `bson:"users"`
	Groups []models.Permissions `bson:"groups"`
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

	var m *MachineDocument
	if err := db.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"credential": conf.Username}).One(&m)
	}); err != nil {
		return err
	}

	w := new(tabwriter.Writer)
	w.Init(os.Stdout, 10, 8, 0, '\t', 0)
	fmt.Fprintf(w, "============= MongoDB Data ==========\n\n")

	fmt.Fprintf(w, "MachineId:\t%s\n", m.Id.Hex())
	fmt.Fprintln(w)

	fmt.Fprintf(w, "Instance Id:\t%s\n", m.Meta.InstanceId)
	fmt.Fprintf(w, "Instance Type:\t%s\n", m.Meta.InstanceType)
	fmt.Fprintf(w, "Region:\t%s\n", m.Meta.Region)
	fmt.Fprintf(w, "Status:\t%s (%s)\n", m.Status.State, m.Status.Reason)
	fmt.Fprintln(w)

	w.Flush()

	return nil
}
