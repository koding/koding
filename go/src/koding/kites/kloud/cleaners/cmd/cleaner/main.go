package main

import (
	"fmt"
	"os"
	"sync"

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

	// HostedZone for production machines
	HostedZone string `default:"koding.io"`

	SlackURL string
}

type task interface {
	Process()
	Result() string
}

func main() {
	if err := realMain(); err != nil {
		fmt.Fprintf(os.Stderr, err.Error())
		os.Exit(1)
	}

	os.Exit(0)
}

func realMain() error {
	conf := new(Config)
	multiconfig.New().MustLoad(conf)

	c := NewCleaner(conf)
	isPaid, err := c.IsPaid()
	if err != nil {
		return err
	}

	instances := c.AWS.FetchInstances()
	alwaysOnMachines, err := c.MongoDB.AlwaysOn()
	if err != nil {
		return err
	}

	c.run(
		&TestVMS{
			Instances: instances,
		},
		&AlwaysOn{
			MongoDB:          c.MongoDB,
			IsPaid:           isPaid,
			AlwaysOnMachines: alwaysOnMachines,
		},
		&LongRunning{
			MongoDB:   c.MongoDB,
			IsPaid:    isPaid,
			Instances: instances,
			Cleaner:   c,
		},
	)

	return nil
}

func (c *Cleaner) run(tasks ...task) {
	c.Log.Info("Running '%d' cleaners", len(tasks))

	var wg sync.WaitGroup

	out := make(chan task)

	for _, t := range tasks {
		wg.Add(1)
		go func(t task) {
			t.Process()
			out <- t
			wg.Done()
		}(t)
	}

	go func() {
		wg.Wait()
		close(out)
	}()

	for t := range out {
		if msg := t.Result(); msg != "" {
			fmt.Println(msg)
			c.Slack(msg) // send to slack channel
		}
	}
}
