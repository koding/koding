package main

import (
	"flag"
	"fmt"
	"os"
	"sync"

	"github.com/koding/multiconfig"
)

var (
	flagConfigFile = flag.String("c", "", "Configuration TOML file")
)

type Config struct {
	// AWS Access and Secret Key
	Aws struct {
		AccessKey string `required:"true"`
		SecretKey string `required:"true"`
	}

	// MongoDB
	MongoURL string `required:"true"`

	// Postgres
	Postgres struct {
		Host     string `default:"localhost"`
		Port     int    `default:"5432"`
		Username string `required:"true"`
		Password string `required:"true"`
		DBName   string `required:"true" `
	}

	// HostedZone for production machines
	HostedZone string `default:"koding.io"`

	Slack struct {
		URL string
	}

	DryRun bool
}

type task interface {
	// Process processes the data and generated the final data to be executed
	Process()

	// Run runs the required action from the generated data. For example it
	// terminates the instances, stops the machines and so on
	Run()

	// Results returns the result from the generated data and executed action.
	Result() string

	// Info returns information about the task itself and the taks responsibilites.
	Info() *taskInfo
}

type taskInfo struct {
	Title string
	Desc  string
}

func main() {
	if err := realMain(); err != nil {
		fmt.Fprintf(os.Stderr, err.Error())
		os.Exit(1)
	}

	os.Exit(0)
}

func realMain() error {
	flag.Parse()

	// If a file is provided use it first
	m := multiconfig.New()
	if *flagConfigFile != "" {
		// we need to create a separate loader because our own flag conflicts
		// with the flagLoader, so we create a new loader wit
		m = &multiconfig.DefaultLoader{
			Loader: multiconfig.MultiLoader(
				&multiconfig.TOMLLoader{Path: *flagConfigFile},
				&multiconfig.TagLoader{},
				&multiconfig.EnvironmentLoader{},
			),
			Validator: multiconfig.MultiValidator(
				&multiconfig.RequiredValidator{},
			),
		}
	}

	conf := new(Config)
	m.MustLoad(conf)

	c := NewCleaner(conf)
	if c.DryRun {
		c.Log.Warning("Dry run is enabled.")
		c.Slack("Cleaner started in dry-run mode", "", "")
	}

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
			if !c.DryRun {
				t.Run()
			}
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
			info := t.Info()
			c.Slack(info.Title, info.Desc, msg) // send to slack channel
		}
	}
}
