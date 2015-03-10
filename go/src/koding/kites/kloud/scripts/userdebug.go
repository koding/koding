package main

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/multiec2"
	"os"
	"text/tabwriter"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

type Config struct {
	Username string `required:"true"`
	MongoURL string `required:"true"`

	AccessKey string `required:"true"`
	SecretKey string `required:"true"`
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
	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	ec2clients := multiec2.New(auth, []string{
		"us-east-1",
		"ap-southeast-1",
		"us-west-2",
		"eu-west-1",
	})

	var m *MachineDocument
	if err := db.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"credential": conf.Username}).One(&m)
	}); err != nil {
		return err
	}

	w := new(tabwriter.Writer)
	defer w.Flush()
	w.Init(os.Stdout, 10, 8, 0, '\t', 0)
	fmt.Fprintf(w, "============= MongoDB ==========\n")

	fmt.Fprintf(w, "MachineId:\t%s\n", m.Id.Hex())
	fmt.Fprintf(w, "Instance Id:\t%s\n", m.Meta.InstanceId)
	fmt.Fprintf(w, "Instance Type:\t%s\n", m.Meta.InstanceType)
	fmt.Fprintf(w, "Region:\t%s\n", m.Meta.Region)
	fmt.Fprintf(w, "IP Address:\t%s\n", m.IpAddress)
	fmt.Fprintf(w, "Storage Size:\t%d\n", m.Meta.StorageSize)
	fmt.Fprintf(w, "Status:\t%s (%s)\n", m.Status.State, m.Status.Reason)
	fmt.Fprintln(w)

	if m.Meta.Region == "" {
		return nil
	}

	client, err := ec2clients.Region(m.Meta.Region)
	if err != nil {
		return err
	}

	resp, err := client.Instances([]string{m.Meta.InstanceId}, ec2.NewFilter())
	if err != nil {
		return err
	}

	if len(resp.Reservations) == 0 {
		return errors.New("resp.Reservation shouldn't be null")
	}

	instances := resp.Reservations[0]
	if len(instances.Instances) == 0 {
		return errors.New("instances.Instances shouldn't be null")
	}
	i := instances.Instances[0]

	fmt.Fprintf(w, "============= AWS ==========\n")
	fmt.Fprintf(w, "IP Address:\t%s\n", i.PublicIpAddress)
	fmt.Fprintf(w, "State:\t%s\n", i.State.Name)
	fmt.Fprintf(w, "Image Id:\t%s\n", i.ImageId)
	fmt.Fprintf(w, "Availibility Zone:\t%s\n", i.AvailZone)
	fmt.Fprintf(w, "Launch Time:\t%s\n", i.LaunchTime)

	if len(i.BlockDevices) == 0 {
		return errors.New("VM doesn't have any block devices!")
	}

	volResp, err := client.Volumes([]string{i.BlockDevices[0].VolumeId}, ec2.NewFilter())
	if err != nil {
		return err
	}

	if len(volResp.Volumes) == 0 {
		return errors.New("volResp.Volumes shouldn't be null")
	}

	volume := volResp.Volumes[0]
	fmt.Fprintf(w, "Storage Size:\t%s\n", volume.Size)

	return nil
}
