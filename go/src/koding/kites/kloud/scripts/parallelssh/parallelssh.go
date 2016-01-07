package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/user"
	"path/filepath"
	"strings"
	"sync"
	"text/tabwriter"
	"time"

	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/provider/koding"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/multiconfig"
	"golang.org/x/crypto/ssh"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

type Config struct {
	MongoURL       string `required:"true"`
	AccessKey      string `required:"true"`
	SecretKey      string `required:"true"`
	HostedZone     string `required:"true"`
	PrivateKey     []byte
	PrivateKeyPath string // default is $USER/.ssh/koding_rsa
}

func NewConfig(file string) (*Config, error) {
	c := &Config{}
	multiconfig.MustLoadWithPath(file, c)
	if c.PrivateKey == nil {
		if c.PrivateKeyPath == "" {
			u, err := user.Current()
			if err != nil {
				return nil, err
			}
			c.PrivateKeyPath = filepath.Join(u.HomeDir, ".ssh", "koding_rsa")
		}
		p, err := ioutil.ReadFile(c.PrivateKeyPath)
		if err != nil {
			return nil, err
		}
		c.PrivateKey = p
	}
	return c, nil
}

func main() {
	if err := realMain(); err != nil {
		fmt.Fprint(os.Stderr, err.Error())
		os.Exit(1)
	}
	// for range time.Tick(time.Minute * 2) {
	// 	if err := realMain(); err != nil {
	// 		fmt.Fprint(os.Stderr, err.Error())
	// 		os.Exit(1)
	// 	}
	// }

	os.Exit(0)
}

func realMain() error {
	conf, err := NewConfig("config.toml")
	if err != nil {
		return err
	}

	db := mongodb.NewMongoDB(conf.MongoURL)
	opts := &amazon.ClientOptions{
		Credentials: credentials.NewStaticCredentials(conf.AccessKey, conf.SecretKey, ""),
		Regions:     amazon.ProductionRegions,
	}
	_, err = amazon.NewClientPerRegion(opts)
	if err != nil {
		return err
	}

	w := new(tabwriter.Writer)
	w.Init(os.Stdout, 10, 8, 0, '\t', 0)
	defer w.Flush()

	// We use a counting semaphore to limit the number of parallel SSH calls
	// per process and to start machines
	var semaSSH = make(chan bool, 50)

	var semaStart = make(chan bool, 10)

	// search via username, mongodb -> aws
	ms, err := machineFromMongodb(db)
	if err != nil {
		return err
	}

	ms.Print(w)

	ips := make([]string, 0)
	var attachWg sync.WaitGroup

	username := make([]string, len(ms.docs))
	for i, machine := range ms.docs {
		username[i] = machine.Credential
	}

	out, err := json.MarshalIndent(username, "", " ")
	if err != nil {
		return err
	}

	if err := ioutil.WriteFile("users.json", out, 0755); err != nil {
		return err
	}

	fmt.Printf("len(username) = %+v\n", len(username))
	for _, machine := range ms.docs {
		attachWg.Add(1)

		go func(machine koding.Machine) {
			semaStart <- true
			defer func() {
				attachWg.Done()
				<-semaStart
			}()

			if machine.Meta.Region == "" {
				return
			}

			// if machine.Status.State == "Running" ||
			// 	machine.Status.State == "NotInitialized" {
			// 	return
			// }

			if machine.IpAddress == "" {
				return
			}

			// log.Printf("Starting %+v\n", machine.Id.Hex())
			// _, err := exec.Command("kloudctl", "start", "-ids", machine.Id.Hex(), "--kloud-addr", "https://koding.com/kloud/kite").CombinedOutput()
			// if err != nil {
			// 	return
			// }
			//
			// time.Sleep(time.Minute * 1)

			// if machine.IpAddress == "" {
			// 	return
			// }

			ips = append(ips, machine.IpAddress)
		}(machine)
	}

	// return nil

	log.Println("starting all machines ...")
	attachWg.Wait()
	log.Println("starting is finished")

	command := "/opt/kite/klient/klient --version"
	update := "cd /tmp && wget https://s3.amazonaws.com/koding-klient/production/31/klient_0.1.31_production_amd64.deb && dpkg -i klient_0.1.31_production_amd64.deb && rm klient_0.1.31_production_amd64.deb"

	log.Printf("executing the command '%s' on %d machines\n\n", command, len(ips))

	var wg sync.WaitGroup
	for _, ip := range ips {
		wg.Add(1)

		go func(ip string) {
			semaSSH <- true // wait
			defer func() {
				wg.Done()
				<-semaSSH
			}()

			done := make(chan string, 0)
			go func() {
				out, err := executeSSHCommand(conf.PrivateKey, ip, command)
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
				if out == "0.1.30" {
					return
				}

				if out == "0.1.31" {
					return
				}

				fmt.Printf("[%s] version: %s updating\n", ip, out)
				_, err := executeSSHCommand(conf.PrivateKey, ip, update)
				if err != nil {
					log.Printf("[%s] updater err: %s\n", ip, err)
					return
				}
			}
		}(ip)
	}

	wg.Wait()

	// fmt.Printf("%d machines with version 0.1.30\n", v30)
	// fmt.Printf("%d machines with version 0.1.99\n", vOther)

	return nil
}

func machineFromMongodb(db *mongodb.MongoDB) (*machines, error) {
	from, err := time.Parse(time.RFC3339, "2015-03-07T13:15:00Z")
	if err != nil {
		return nil, err
	}

	to, err := time.Parse(time.RFC3339, "2015-04-10T07:30:00Z")
	if err != nil {
		return nil, err
	}

	machines := newMachines()
	err = db.Run("jMachines", func(c *mgo.Collection) error {
		var m koding.Machine
		iter := c.Find(
			bson.M{
				"createdAt": bson.M{
					"$gte": from.UTC(),
					"$lt":  to.UTC(),
				},
				// "status.state": machinestate.Stopped.String(),
			},
		).Iter()

		for iter.Next(&m) {
			machines.docs = append(machines.docs, m)
		}

		return iter.Close()
	})

	return machines, err
}

func newMachines() *machines {
	return &machines{
		docs: make([]koding.Machine, 0),
	}
}

type machines struct {
	docs []koding.Machine
}

func (m *machines) Print(w io.Writer) {
	fmt.Fprintf(w, "============= MongoDB ('%d' docs) ==========\n", len(m.docs))
}

func executeSSHCommand(privateKey []byte, ipAddress, command string) (string, error) {
	client, err := ConnectSSH(privateKey, ipAddress)
	if err != nil {
		return "", err
	}

	output, err := client.StartCommand(command)
	if err != nil {
		return "", err
	}
	defer client.Close()

	return strings.TrimSpace(string(output)), nil
}

type SSHClient struct {
	*ssh.Client
}

func ConnectSSH(privateKey []byte, ip string) (*SSHClient, error) {
	signer, err := ssh.ParsePrivateKey(privateKey)
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
