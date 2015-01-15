package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"os"
	"time"

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
	duplicates := make(map[string]struct{}, 0)            // list of users with machines more than one

	go func() {
		time.Sleep(time.Second * 20)
		fmt.Printf("Users: %d Duplicates: %d\n", len(users), len(duplicates))
	}()

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
		duplicates[username] = struct{}{}
	}
	start := time.Now()
	if err := m.Iter(iter); err != nil {
		return err
	}
	fmt.Println("Mongodb fetching finished", time.Since(start))

	fmt.Println("Listing non paid users with more than one VMs")
	for user := range duplicates {
		if !isPaid(user) {
			fmt.Printf("Username: '%s'. Total machine count: %d\n", user, len(users[user]))
		}
	}

	return nil
}
