package main

import (
	"errors"
	"fmt"
	"io"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/pkg/multiec2"
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
	MongoURL  string `required:"true"`
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
	multiconfig.MustLoadWithPath("config.toml", conf)

	db := mongodb.NewMongoDB(conf.MongoURL)
	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	_ = multiec2.New(auth, []string{
		"us-east-1",
		"ap-southeast-1",
		"us-west-2",
		"eu-west-1",
	})

	w := new(tabwriter.Writer)
	w.Init(os.Stdout, 10, 8, 0, '\t', 0)
	defer w.Flush()

	// search via username, mongodb -> aws
	ms, err := machinesFromUsername(db)
	if err == nil {
		ms.Print(w)
	} else {
		fmt.Fprintf(os.Stderr, err.Error())
	}

	return nil
}

func machinesFromUsername(db *mongodb.MongoDB) (*machines, error) {
	from, err := time.Parse(time.RFC3339, "2015-04-07T13:15:00Z")
	if err != nil {
		return nil, err
	}

	to, err := time.Parse(time.RFC3339, "2015-04-08T09:30:00Z")
	if err != nil {
		return nil, err
	}

	machines := newMachines()
	err = db.Run("jUsers", func(c *mgo.Collection) error {
		var m MachineDocument
		iter := c.Find(bson.M{"registeredAt": bson.M{
			"$gte": from.UTC(),
			"$lt":  to.UTC(),
		},
		}).Iter()

		for iter.Next(&m) {
			machines.docs = append(machines.docs, m)
		}

		return iter.Close()
	})

	return machines, err
}

func newMachines() *machines {
	return &machines{
		docs: make([]MachineDocument, 0),
	}
}

type machines struct {
	docs []MachineDocument
}

func (m *machines) Print(w io.Writer) {
	fmt.Fprintf(w, "============= MongoDB ('%d' docs) ==========\n", len(m.docs))
}

type instance struct {
	ec2    ec2.Instance
	volume ec2.Volume
}

func (i *instance) Print(w io.Writer) {
	fmt.Fprintf(w, "============= AWS ==========\n")
	fmt.Fprintf(w, "InstanceId:\t%s\n", i.ec2.InstanceId)
	fmt.Fprintf(w, "IP Address:\t%s\n", i.ec2.PublicIpAddress)
	fmt.Fprintf(w, "State:\t%s\n", i.ec2.State.Name)
	fmt.Fprintf(w, "Image Id:\t%s\n", i.ec2.ImageId)
	fmt.Fprintf(w, "Availibility Zone:\t%s\n", i.ec2.AvailZone)
	fmt.Fprintf(w, "Launch Time:\t%s\n", i.ec2.LaunchTime)
	fmt.Fprintf(w, "Storage Size:\t%s\n", i.volume.Size)
}

func awsData(client *ec2.EC2, instanceId string) (*instance, error) {
	resp, err := client.Instances([]string{instanceId}, ec2.NewFilter())
	if err != nil {
		return nil, err
	}

	if len(resp.Reservations) == 0 {
		return nil, errors.New("resp.Reservation shouldn't be null")
	}

	instances := resp.Reservations[0]
	if len(instances.Instances) == 0 {
		return nil, errors.New("instances.Instances shouldn't be null")
	}

	i := instances.Instances[0]

	var volume ec2.Volume
	if len(i.BlockDevices) != 0 {
		volResp, err := client.Volumes([]string{i.BlockDevices[0].VolumeId}, ec2.NewFilter())
		if err != nil {
			return nil, err
		}

		if len(volResp.Volumes) == 0 {
			return nil, errors.New("volResp.Volumes shouldn't be null")
		}

		volume = volResp.Volumes[0]
	}

	return &instance{
		ec2:    i,
		volume: volume,
	}, nil
}
