package main

import (
	"flag"
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
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
	MongoURL        string `required:"true"`
	SandboxMongoURL string `required:"true"`

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

	DryRun      bool
	Interval    string `required:"true"`
	EIPInterval string `default:"1h"`
	Debug       bool
	MaxResults  int `default:"500"`
	BatchLimit  int `default:"200"` // NOTE: AWS does not allow batching more than 200 items

	// EIPOnly when true makes cleaner run only Elastic IP related tasks.
	EIPOnly bool

	// StoppedOnly says whether to clean EIP from stopped instnace of non-paying
	// users
	//
	// By default cleaned also from running ones as well.
	StoppedOnly bool
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
	if cl.Config.Debug {
		cl.Log.Warning("Debug mode is enabled.")
	}
	if cl.Config.DryRun {
		cl.Log.Warning("Dry run is enabled.")
		if !cl.Config.Debug {
			cl.Slack("Cleaner started in dry-run mode", "", "")
		}
	}
	if cl.Config.EIPOnly {
		cl.Log.Warning("Running only EIP related tasks")
	}

	interval, err := time.ParseDuration(conf.Interval)
	if err != nil {
		return err
	}

	shortInterval, err := time.ParseDuration(conf.EIPInterval)
	if err != nil {
		return err
	}

	// time.Ticker always sends first tick after the specified duration,
	// in order to have tasks executed after the process is started,
	// we create proxy tickers with first tick enqueued.
	tick := make(chan time.Time, 1)
	tickEIP := make(chan time.Time, 1)

	tick <- time.Now()
	tickEIP <- time.Now()

	go func() {
		for t := range time.Tick(interval) {
			tick <- t
		}
	}()

	go func() {
		for t := range time.Tick(shortInterval) {
			tickEIP <- t
		}
	}()

	for {
		select {
		case <-tick:
			cl.Run()
		case <-tickEIP:
			cl.RunEIP()
		}
	}

	select {}
}

func (c *Cleaner) Run() {
	c.Log.Info("Cleaner started long run ...")
	defer c.Log.Info("Cleaner finished long run")

	if err := c.collectAndProcess(); err != nil {
		c.Log.Error(err.Error())
	}
}

func (c *Cleaner) RunEIP() {
	c.Log.Info("Cleaner started Elastic IP run ...")
	defer c.Log.Info("Cleaner finished Elastic IP run")

	tasks := []task{
		&ElasticIPs{
			Lookup: c.AWS,
		},
	}

	isPaid, err := c.IsPaid()
	if err != nil {
		c.Log.Error(err.Error())
	} else {
		tasks = append(tasks, &DowngradedElasticIPs{
			Lookup: c.AWS,
			Options: &lookup.NotPaidOptions{
				BatchLimit: c.Config.BatchLimit,
				CleanAll:   !c.Config.StoppedOnly,
				IsPaid:     isPaid,
				Log:        c.Log.New("not-paid"),
			},
		})
	}

	c.process(tasks...)
}

// collectAndRun collects any necessary resource and processes all task
func (c *Cleaner) collectAndProcess() error {
	if c.Config.EIPOnly {
		c.Log.Debug("skipping running tasks other than EIP ones")
		return nil
	}

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
			MongoDB:   c.SandboxMongoDB.DB,
		},
		&TestDomains{
			DNS: c.DNSDev,
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
			if !c.Config.DryRun {
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

		if c.Config.DryRun {
			info.Title += info.Title + " (dry-run)"
		}

		if !c.Config.Debug {
			c.Slack(info.Title, info.Desc, msg) // send to slack channel
		}

		t = nil
	}

	out = nil
}
