package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
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

	m := lookup.NewMongoDB(conf.MongoURL)
	l := lookup.NewAWS(aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	})
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

	fmt.Printf("Searching for [running] instances tagged with [production] and older than 12 hours ...\n")

	instances := l.FetchInstances().
		OlderThan(12*time.Hour).
		States("running").
		WithTag("koding-env", "production")

	fmt.Printf("Found '%d' instances, fetching MongoDB documents of those instances\n", instances.Total())

	machines, err := m.Machines(instances.Ids()...)
	if err != nil {
		return err
	}

	longRunningVMS := make(map[string]string, 0)

	for _, machine := range machines {
		// there is no way this can panic because we fetch documents which
		// have instanceIds in it
		instanceId := machine.Meta["instanceId"].(string)
		username := machine.Credential

		// if user is not a paying customer
		if !isPaid(username) {
			longRunningVMS[instanceId] = username
		}
	}

	for instanceId, username := range longRunningVMS {
		fmt.Printf("[%s] %s\n", username, instanceId)
	}

	fmt.Printf("\nFound '%d' machines belonging to free users which are running more than 12 hours\n",
		len(longRunningVMS))

	return nil
}
