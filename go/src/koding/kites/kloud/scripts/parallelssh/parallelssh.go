package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/pkg/multiec2"
	"log"
	"os"
	"strings"
	"sync"
	"text/tabwriter"
	"time"

	"golang.org/x/crypto/ssh"

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

	// We use a counting semaphore to limit
	// the number of parallel SSH calls per process.
	var sema = make(chan bool, 50)

	// search via username, mongodb -> aws
	ms, err := machinesFromUsername(db)
	if err != nil {
		return err
	}

	ms.Print(w)

	ips := make([]string, 0)
	for _, machine := range ms.docs {
		if machine.IpAddress == "" {
			continue
		}

		ips = append(ips, machine.IpAddress)
	}

	command := "/opt/kite/klient/klient --version"
	update := "cd /tmp && wget https://s3.amazonaws.com/koding-klient/production/30/klient_0.1.30_production_amd64.deb && dpkg -i klient_0.1.30_production_amd64.deb && rm klient_0.1.30_production_amd64.deb"

	var wg sync.WaitGroup
	for _, ip := range ips {
		wg.Add(1)

		go func(ip string) {
			sema <- true // wait
			defer func() {
				wg.Done()
				<-sema
			}()

			done := make(chan string, 0)
			go func() {
				out, err := executeSSHCommand(ip, command)
				if err != nil {
					return
				}

				done <- out
			}()

			select {
			case <-time.After(time.Second * 10):
				// cancel operation after 10 seconds
				// fmt.Printf("[%s] canceling operation\n", ip)
				return
			case out := <-done:
				if out != "0.1.30" {
					fmt.Printf("[%s] version: %s updating\n", ip, out)
					_, err := executeSSHCommand(ip, update)
					if err != nil {
						log.Printf("[%s] updater err: %s\n", ip, err)
						return
					}

					// log.Printf("[%s] update result: %s\n", ip, out)
				}
			}
		}(ip)
	}

	fmt.Printf("executing the command '%s' on %d machines\n\n", command, len(ips))

	wg.Wait()

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
	err = db.Run("jMachines", func(c *mgo.Collection) error {
		var m MachineDocument
		iter := c.Find(bson.M{"createdAt": bson.M{
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

func executeSSHCommand(ipAddress, command string) (string, error) {
	client, err := ConnectSSH(ipAddress)
	if err != nil {
		return "", err
	}

	output, err := client.StartCommand(command)
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(output)), nil
}

type SSHClient struct {
	*ssh.Client
}

func ConnectSSH(ip string) (*SSHClient, error) {
	signer, err := ssh.ParsePrivateKey([]byte(publickeys.DeployPrivateKey))
	if err != nil {
		return nil, fmt.Errorf("Error setting up SSH config: %s", err)
	}

	config := &ssh.ClientConfig{
		User: "root",
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
	}

	client, err := ssh.Dial("tcp", ip+":22", config)
	if err != nil {
		return nil, err
	}

	return &SSHClient{Client: client}, nil
}

func (s *SSHClient) StartCommand(command string) (string, error) {
	session, err := s.NewSession()
	if err != nil {
		return "", err
	}
	defer session.Close()

	combinedOutput := new(bytes.Buffer)
	session.Stdout = combinedOutput
	session.Stderr = combinedOutput

	if err := session.Start(command); err != nil {
		return "", err
	}

	// Wait for the SCP connection to close, meaning it has consumed all
	// our data and has completed. Or has errored.
	err = session.Wait()
	if err != nil {
		if exitErr, ok := err.(*ssh.ExitError); ok {
			// Otherwise, we have an ExitErorr, meaning we can just read
			// the exit status
			log.Printf("non-zero exit status: %d", exitErr.ExitStatus())

			// If we exited with status 127, it means SCP isn't available.
			// Return a more descriptive error for that.
			if exitErr.ExitStatus() == 127 {
				return "", errors.New(
					"SCP failed to start. This usually means that SCP is not\n" +
						"properly installed on the remote system.")
			}
		}

		return combinedOutput.String(), err
	}

	return combinedOutput.String(), nil
}
