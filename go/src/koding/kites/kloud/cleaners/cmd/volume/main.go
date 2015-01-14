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

	// Terminate terminates not used Volumes
	Terminate bool
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

	volumes := l.FetchVolumes().GreaterThan(3)

	fmt.Printf("Total volumes greater than 3GB: %+v\n", volumes.Total())
	fmt.Println(volumes)

	inUse := volumes.Status("in-use")
	fmt.Printf("Total volumes that are used: %+v\n", inUse.Total())

	// we select one hour old volumes to avoid currently running resize operations
	available := volumes.Status("available").OlderThan(time.Hour)
	if available.Total() > 0 {
		fmt.Printf("Total volumes that are not used: %+v.\n",
			available.Total())
		if conf.Terminate {
			available.TerminateAll()
		} else {
			fmt.Printf("To delete all Volumes run the command again with the flag -terminate\n")
		}
	}

	for _, ids := range volumes.InstanceIds() {
		machines, err := m.Machines(ids...)
		if err != nil {
			return err
		}

		for _, machine := range machines {
			username := machine.Credential

			// if user is not a paying customer
			if !isPaid(username) {
				fmt.Printf("username = %+v\n", username)
			}

		}
	}

	return nil
}
