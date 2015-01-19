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
	artifacts, err := c.Collect()
	if err != nil {
		return err
	}

	c.run(
		&TestVMS{
			Instances: artifacts.Instances,
		},
		&AlwaysOn{
			MongoDB:          c.MongoDB,
			IsPaid:           artifacts.IsPaid,
			AlwaysOnMachines: artifacts.AlwaysOnMachines,
		},
		&LongRunning{
			MongoDB:   c.MongoDB,
			IsPaid:    artifacts.IsPaid,
			Instances: artifacts.Instances,
			Cleaner:   c,
		},
		&GhostVMs{
			MongoDB:   c.MongoDB,
			Instances: artifacts.Instances,
			Ids:       artifacts.MongodbIDs,
		},
		&MultipleVMs{
			Instances:     artifacts.Instances,
			UsersMultiple: artifacts.UsersMultiple,
			IsPaid:        artifacts.IsPaid,
			Cleaner:       c,
		},
		&Volumes{
			MongoDB:   c.MongoDB,
			IsPaid:    artifacts.IsPaid,
			Instances: artifacts.Instances,
			Volumes:   artifacts.Volumes,
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
			c.Log.Info(msg)
			c.Slack(msg) // send to slack channel
		}
	}
}
