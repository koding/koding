package main

import (
	"fmt"
	"io"
	"os"
	"strconv"
	"text/tabwriter"
	"time"

	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

type Config struct {
	Username   string
	InstanceId string

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
	Users  []models.MachineUser  `bson:"users"`
	Groups []models.MachineGroup `bson:"groups"`
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
	opts := &amazon.ClientOptions{
		Credentials: credentials.NewStaticCredentials(conf.AccessKey, conf.SecretKey, ""),
		Regions:     amazon.ProductionRegions,
		Log:         logging.NewLogger("userdebug"),
	}
	ec2clients, err := amazon.NewClients(opts)
	if err != nil {
		panic(err)
	}

	w := new(tabwriter.Writer)
	w.Init(os.Stdout, 10, 8, 0, '\t', 0)
	defer w.Flush()

	// search via username, mongodb -> aws
	if conf.Username != "" {
		ms, err := machinesFromUsername(db, conf.Username)
		if err == nil {
			ms.Print(w)

			for _, m := range ms.docs {
				// if the mongodb document has a region and instanceId, display it too
				if m.Meta.Region != "" && m.Meta.InstanceId != "" {
					client, err := ec2clients.Region(m.Meta.Region)
					if err != nil {
						return err
					}

					i, err := awsData(client, m.Meta.InstanceId)
					if err != nil {
						return err
					}

					i.Print(w)
				}
			}
		} else {
			fmt.Fprintf(os.Stderr, err.Error())
		}
	}

	// search via instanceId, aws -> mongodb
	if conf.InstanceId != "" {
		for _, client := range ec2clients.Regions() {
			i, err := awsData(client, conf.InstanceId)
			if err != nil {
				continue // if not found continue with next region
			}

			// if we find a mongoDB document display it
			ms, err := machinesFromInstanceId(db, conf.InstanceId)
			if err == nil {
				ms.Print(w)
			}

			i.Print(w)
			break
		}
	}

	return nil
}

func machinesFromUsername(db *mongodb.MongoDB, username string) (*machines, error) {
	machines := newMachines()
	err := db.Run("jMachines", func(c *mgo.Collection) error {
		var m MachineDocument
		iter := c.Find(bson.M{"credential": username}).Iter()

		for iter.Next(&m) {
			machines.docs = append(machines.docs, m)
		}

		return iter.Close()
	})

	return machines, err
}

func machinesFromInstanceId(db *mongodb.MongoDB, instanceId string) (*machines, error) {
	machines := newMachines()
	err := db.Run("jMachines", func(c *mgo.Collection) error {
		var m MachineDocument
		iter := c.Find(bson.M{"meta.instanceId": instanceId}).Iter()

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

	for _, machine := range m.docs {
		fmt.Fprintf(w, "Username:\t%s\n", machine.Credential)
		fmt.Fprintf(w, "MachineId:\t%s\n", machine.Id.Hex())
		fmt.Fprintf(w, "Instance Id:\t%s\n", machine.Meta.InstanceId)
		fmt.Fprintf(w, "Instance Type:\t%s\n", machine.Meta.InstanceType)
		fmt.Fprintf(w, "Region:\t%s\n", machine.Meta.Region)
		fmt.Fprintf(w, "IP Address:\t%s\n", machine.IpAddress)
		fmt.Fprintf(w, "Storage Size:\t%d\n", machine.Meta.StorageSize)
		fmt.Fprintf(w, "Status:\t%s (%s)\n", machine.Status.State, machine.Status.Reason)
		fmt.Fprintln(w)
	}
}

type instance struct {
	ec2    *ec2.Instance
	status *ec2.InstanceStatus
	volume *ec2.Volume
}

func (i *instance) volumeSize() string {
	if i.volume != nil {
		return strconv.FormatInt(aws.Int64Value(i.volume.Size), 10)
	}
	return "(no block devices attached)"
}

func (i *instance) Print(w io.Writer) {
	fmt.Fprintf(w, "============= AWS ==========\n")
	fmt.Fprintf(w, "InstanceId:\t%s\n", aws.StringValue(i.ec2.InstanceId))
	fmt.Fprintf(w, "IP Address:\t%s\n", aws.StringValue(i.ec2.PublicIpAddress))
	fmt.Fprintf(w, "State:\t%s\n", aws.StringValue(i.ec2.State.Name))
	fmt.Fprintf(w, "Image Id:\t%s\n", aws.StringValue(i.ec2.ImageId))
	fmt.Fprintf(w, "Availibility Zone:\t%s\n", aws.StringValue(i.status.AvailabilityZone))
	fmt.Fprintf(w, "Launch Time:\t%s\n", aws.TimeValue(i.ec2.LaunchTime))
	fmt.Fprintf(w, "Storage Size:\t%s\n", i.volumeSize())
}

func awsData(client *amazon.Client, instanceId string) (i *instance, err error) {
	i = &instance{}
	i.ec2, err = client.InstanceByID(instanceId)
	if err != nil {
		return nil, err
	}
	i.status, err = client.InstanceStatusByID(instanceId)
	if err != nil {
		return nil, err
	}

	if len(i.ec2.BlockDeviceMappings) != 0 {
		i.volume, err = client.VolumeByID(aws.StringValue(i.ec2.BlockDeviceMappings[0].Ebs.VolumeId))
		if err != nil {
			return nil, err
		}
	}

	return i, nil
}
