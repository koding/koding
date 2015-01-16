package main

import (
	"errors"
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"koding/kites/kloud/provider/koding"
	"os"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
)

type Config struct {
	// AWS Access and Secret Key
	AccessKey string `required:"true"`
	SecretKey string `required:"true"`

	// MongoDB
	MongoURL string `required:"true"`

	// Postgres
	Host     string `default:"localhost"`
	Port     int    `default:"5432"`
	Username string `required:"true"`
	Password string `required:"true"`
	DBName   string `required:"true" `

	// HostedZone for production machines
	HostedZone string `default:"koding.io"`

	// Stop long running machines
	Stop bool
}

func main() {
	if err := realMain(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	os.Exit(0)
}

func realMain() error {
	conf := new(Config)
	multiconfig.New().MustLoad(conf)
	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	m := lookup.NewMongoDB(conf.MongoURL)
	dns := koding.NewDNSClient(conf.HostedZone, auth)
	domainStorage := koding.NewDomainStorage(m.DB)
	l := lookup.NewAWS(auth)
	p := lookup.NewPostgres(&lookup.PostgresConfig{
		Host:     conf.Host,
		Port:     conf.Port,
		Username: conf.Username,
		Password: conf.Password,
		DBName:   conf.DBName,
	})

	payingIds, err := p.PayingCustomers()
	if err != nil {
		return err
	}

	accounts, err := m.Accounts(payingIds...)
	if err != nil {
		return err
	}

	set := make(map[string]struct{}, 0)
	for _, account := range accounts {
		set[account.Profile.Nickname] = struct{}{}
	}

	isPaid := func(username string) bool {
		_, ok := set[username]
		return ok
	}

	fmt.Printf("Searching for [running] instances tagged with [production] older than [12 hours] ...\n")

	instances := l.FetchInstances().
		OlderThan(12*time.Hour).
		States("running").
		WithTag("koding-env", "production")

	machines, err := m.Machines(instances.Ids()...)
	if err != nil {
		return err
	}

	type stopData struct {
		id         bson.ObjectId
		instanceId string
		domain     string
		ipAddress  string
		username   string
	}

	datas := make([]stopData, 0)
	for _, machine := range machines {
		username := machine.Credential
		// if user is a paying customer skip it
		if isPaid(username) {
			continue
		}

		data := stopData{
			id: machine.Id,
			// there is no way this can panic because we fetch documents which
			// have instanceIds in it
			instanceId: machine.Meta["instanceId"].(string),
			domain:     machine.Domain,
			ipAddress:  machine.IpAddress,
			username:   username,
		}

		datas = append(datas, data)

		// debug
		// fmt.Printf("[%s] %s %s %s\n", data.username, data.instanceId, data.domain, data.ipAddress)
	}

	ids := make([]string, 0)
	for _, d := range datas {
		ids = append(ids, d.instanceId)
	}

	longRunningInstances := instances.Only(ids...)
	// contains free user VMs running for more than 12 hours
	if longRunningInstances.Total() == 0 {
		return errors.New("No VMs found.")
	}

	if conf.Stop {
		longRunningInstances.StopAll()
		for _, d := range datas {
			if err := dns.Delete(d.domain, d.ipAddress); err != nil {
				fmt.Printf("[%s] couldn't delete domain %s\n", d.id, err)
			}

			// also get all domain aliases that belongs to this machine and unset
			domains, err := domainStorage.GetByMachine(d.id.Hex())
			if err != nil {
				fmt.Errorf("[%s] fetching domains for unseting err: %s\n", d.id, err.Error())
			}

			for _, ds := range domains {
				if err := dns.Delete(ds.Name, d.ipAddress); err != nil {
					fmt.Errorf("[%s] couldn't delete domain: %s", d.id, err.Error())
				}
			}

			// delete ipAdress, stopped instances doesn't have any ipAdresses
			m.DB.Run("jMachines", func(c *mgo.Collection) error {
				return c.UpdateId(d.id, bson.M{"$set": bson.M{"ipAddress": ""}})
			})
		}

		fmt.Printf("\nStopped '%d' instances\n", longRunningInstances.Total())
	} else {
		fmt.Printf("Found '%d' free user machines which are running more than 12 hours\n",
			longRunningInstances.Total())
		fmt.Printf("To stop all running free VMS run the command again with the flag -stop\n")
	}

	return nil
}
