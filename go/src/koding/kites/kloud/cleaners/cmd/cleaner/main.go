package main

import (
	"flag"
	"fmt"
	"os"
	"sync"
	"time"

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
		Host     string `required:"true"`
		Port     int    `required:"true"`
		Username string `required:"true"`
		Password string `required:"true"`
		DBName   string `required:"true" `
	}

	// HostedZone for production machines
	HostedZone string `default:"koding.io"`

	Slack struct {
		URL string
	}

	DryRun   bool
	Interval string `required:"true"`
	Debug    bool
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

	cl := NewCleaner(conf)
	if cl.DryRun {
		cl.Log.Warning("Dry run is enabled.")
		if !cl.Debug {
			cl.Slack("Cleaner started in dry-run mode", "", "")
		}
	}

	interval, err := time.ParseDuration(conf.Interval)
	if err != nil {
		return err
	}

	for {
		cl.Run()
		time.Sleep(interval)
	}

	return nil
}

func (c *Cleaner) Run() {
	c.Log.Info("Cleaner start to collect artifacts...")
	if err := c.collectAndProcess(); err != nil {
		c.Log.Error(err.Error())
	}
}

// collectAndRun collects any necessary resource and processes all task
func (c *Cleaner) collectAndProcess() error {
	artifacts, err := c.Collect()
	if err != nil {
		return err
	}

	c.process(
		//&TagInstances{
		//	Instances: artifacts.Instances,
		//	Machines:  artifacts.MongodbUsers,
		//},
		&TestVMS{
			Instances: artifacts.Instances,
		},
		&TestDomains{
			DNS: c.DNSDev,
		},
		&ElasticIPs{
			Lookup: c.AWS,
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
		//&GhostVMs{
		//	Instances: artifacts.Instances,
		//	Ids:       artifacts.MongodbUsers,
		//},
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

func (c *Cleaner) process(tasks ...task) {
	c.Log.Info("Processing and running tasks")

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
		msg := t.Result()
		if msg == "" {
			continue
		}

		info := t.Info()
		c.Log.Info("%s: %s", info.Title, msg)

		if c.DryRun {
			info.Title += info.Title + " (dry-run)"
		}

		if !c.Debug {
			c.Slack(info.Title, info.Desc, msg) // send to slack channel
		}

		t = nil
	}

	out = nil
}
