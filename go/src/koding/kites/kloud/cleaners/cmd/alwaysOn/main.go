package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"log"
	"os"

	"github.com/koding/multiconfig"
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
		log.Println(err)
		os.Exit(1)
	}

	os.Exit(0)
}

func realMain() error {
	conf := new(Config)

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	p := lookup.NewPostgres(&lookup.PostgresConfig{
		Host:     conf.Host,
		Port:     conf.Port,
		Username: conf.Username,
		Password: conf.Password,
		DBName:   conf.DBName,
	})

	m := lookup.NewMongoDB(conf.MongoURL)

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

	alwaysOnMachines, err := m.AlwaysOn()
	if err != nil {
		return err
	}

	fmt.Println("Free users with alwaysOn VMs:")

	nonvalidUsers := make([]string, 0)

	for _, machine := range alwaysOnMachines {
		username := machine.Credential

		// if user is not a paying customer
		if !isPaid(username) {
			nonvalidUsers = append(nonvalidUsers, username)
		}
	}

	for _, user := range nonvalidUsers {
		fmt.Printf("\t%s\n", user)
	}

	return nil
}
