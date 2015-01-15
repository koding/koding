package main

import (
	"errors"
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"koding/kites/kloud/provider/koding"
	"os"
	"time"

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

	ids := make([]string, 0)
	for _, machine := range machines {
		// there is no way this can panic because we fetch documents which
		// have instanceIds in it
		id := machine.Id
		instanceId := machine.Meta["instanceId"].(string)
		domain := machine.Domain
		ipAddress := machine.IpAddress
		username := machine.Credential

		// if user is a paying customer skip it
		if isPaid(username) {
			continue
		}

		// debug
		// fmt.Printf("[%s] %s\n", username, instanceId)
		ids = append(ids, instanceId)

		if err := dns.Delete(domain, ipAddress); err != nil {
			fmt.Printf("[%s] couldn't delete domain %s\n", id, err)
		}

		// also get all domain aliases that belongs to this machine and unset
		domains, err := domainStorage.GetByMachine(id.Hex())
		if err != nil {
			fmt.Errorf("[%s] fetching domains for unseting err: %s\n", id, err.Error())
		}

		for _, domain := range domains {
			if err := dns.Delete(domain.Name, ipAddress); err != nil {
				fmt.Errorf("[%s] couldn't delete domain: %s", id, err.Error())
			}
		}
	}

	// contains free user VMs running for more than 12 hours
	longRunningInstances := instances.Only(ids...)
	if longRunningInstances.Total() == 0 {
		return errors.New("No VMs found.")
	}

	fmt.Printf("\nFound '%d' machines belonging to free users which are running more than 12 hours\n",
		longRunningInstances.Total())

	if conf.Stop {
		longRunningInstances.StopAll()
		fmt.Printf("\nStopped '%d' instances\n", longRunningInstances.Total())
	} else {
		fmt.Printf("To stop all running free VMS run the command again with the flag -stop\n")
	}

	return nil
}
