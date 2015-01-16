package main

import (
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

	fmt.Println("Fetching user VMs from MongoDB ...")

	users := make(map[string][]lookup.MachineDocument, 0) // users mapped to their machines
	usersWithMultipleVms := make(map[string]struct{}, 0)  // list of users with machines more than one

	iter := func(l lookup.MachineDocument) {
		username := l.Credential
		machines, ok := users[username]
		if !ok {
			users[username] = []lookup.MachineDocument{l}
			return
		}

		// we found a duplicate!
		machines = append(machines, l)
		users[username] = machines
		usersWithMultipleVms[username] = struct{}{}
	}
	if err := m.Iter(iter); err != nil {
		return err
	}

	freeUsersWithMultipleVMs := make(map[string]struct{}, 0)
	for user := range usersWithMultipleVms {
		if !isPaid(user) {
			freeUsersWithMultipleVMs[user] = struct{}{}
		}
	}

	fmt.Printf("Found '%d' free user machines with more than one VM\n",
		len(freeUsersWithMultipleVMs))

	return nil
}
