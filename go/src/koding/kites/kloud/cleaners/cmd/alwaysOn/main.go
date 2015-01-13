package main

import (
	"errors"
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
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

	//  Update alwaysOn flag
	Update bool
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

	nonvalidUsers := make([]string, 0)

	for _, machine := range alwaysOnMachines {
		username := machine.Credential

		// if user is not a paying customer
		if !isPaid(username) {
			nonvalidUsers = append(nonvalidUsers, username)
		}
	}

	if len(nonvalidUsers) == 0 {
		return errors.New("No users are available. Everything is ok.")

	}

	fmt.Printf("Free users with alwaysOn VMs: %d\n", len(nonvalidUsers))

	for _, user := range nonvalidUsers {
		fmt.Printf("\t%s\n", user)
	}

	if conf.Update {
		if err := m.RemoveAlwaysOn(nonvalidUsers...); err != nil {
			return err
		}

		fmt.Printf("Updated '%d' jMachines alwaysOn fields to 'false'\n", len(nonvalidUsers))
	} else {
		fmt.Printf("To update the alwaysOn field and set it to false, run again with -update\n")
	}

	return nil
}
