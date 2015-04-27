package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/pkg/dnsclient"
	"sync"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/logging"
	"github.com/mitchellh/goamz/aws"
)

type Cleaner struct {
	AWS      *lookup.Lookup
	MongoDB  *lookup.MongoDB
	Postgres *lookup.Postgres
	DNS      dnsclient.Client
	Domains  dnsstorage.Storage
	DryRun   bool
	Debug    bool

	Hook Hook
	Log  logging.Logger
}

type Artifacts struct {
	Instances        *lookup.MultiInstances
	Volumes          lookup.MultiVolumes
	AlwaysOnMachines []lookup.MachineDocument
	UsersMultiple    map[string][]lookup.MachineDocument
	MongodbUsers     map[string]lookup.MachineDocument
	IsPaid           func(string) bool
}

type StopData struct {
	id         bson.ObjectId
	instanceId string
	domain     string
	ipAddress  string
	username   string
	reason     string
}

func NewCleaner(conf *Config) *Cleaner {
	auth := aws.Auth{
		AccessKey: conf.Aws.AccessKey,
		SecretKey: conf.Aws.SecretKey,
	}

	l := lookup.NewAWS(auth)
	m := lookup.NewMongoDB(conf.MongoURL)
	dns := dnsclient.NewRoute53Client(conf.HostedZone, auth)
	domains := dnsstorage.NewMongodbStorage(m.DB)
	p := lookup.NewPostgres(&lookup.PostgresConfig{
		Host:     conf.Postgres.Host,
		Port:     conf.Postgres.Port,
		Username: conf.Postgres.Username,
		Password: conf.Postgres.Password,
		DBName:   conf.Postgres.DBName,
	})
	// TODO: change once the code is moved to koding/monitoring
	hook := Hook{
		URL:      conf.Slack.URL,
		Channel:  "#reports",
		Username: "cleaner",
	}

	log := logging.NewLogger("cleaner")
	if conf.Debug {
		log.SetLevel(logging.DEBUG)
	}

	return &Cleaner{
		AWS:      l,
		MongoDB:  m,
		Postgres: p,
		DNS:      dns,
		Domains:  domains,
		Hook:     hook,
		Log:      logging.NewLogger("cleaner"),
		DryRun:   conf.DryRun,
		Debug:    conf.Debug,
	}
}

func (c *Cleaner) IsPaid() (func(string) bool, error) {
	payingIds, err := c.Postgres.PayingCustomers()
	if err != nil {
		return nil, err
	}

	accounts, err := c.MongoDB.Accounts(payingIds...)
	if err != nil {
		return nil, err
	}

	set := make(map[string]struct{}, 0)
	for _, account := range accounts {
		set[account.Profile.Nickname] = struct{}{}
	}

	return func(username string) bool {
		_, ok := set[username]
		return ok
	}, nil
}

func (c *Cleaner) Slack(title, desc, msg string) error {
	pretext := title
	if pretext != "" {
		pretext = "*" + title + "*"
	}

	if desc != "" {
		pretext = fmt.Sprintf("%s: _%s_", pretext, desc)
	}

	text := msg
	if text != "" {
		text = "`" + msg + "`"
	}

	attachments := []Attachment{
		{
			Fallback: title,
			PreText:  pretext,
			Text:     text,
			MrkdwnIn: []string{"text", "title", "pretext", "fallback"},
		},
	}

	return c.Hook.Post(Message{
		Channel:     c.Hook.Channel,
		Username:    c.Hook.Username,
		Text:        "",
		IconEmoji:   ":cl:",
		Attachments: attachments,
	})
}

func (c *Cleaner) StopMachine(data *StopData) {
	if err := c.DNS.Delete(data.domain); err != nil {
		fmt.Printf("[%s] couldn't delete domain %s\n", data.id, err)
	}

	// also get all domain aliases that belongs to this machine and unset
	domains, err := c.Domains.GetByMachine(data.id.Hex())
	if err != nil {
		fmt.Printf("[%s] fetching domains for unseting err: %s\n", data.id, err.Error())
	}

	for _, ds := range domains {
		if err := c.DNS.Delete(ds.Name); err != nil {
			fmt.Printf("[%s] couldn't delete domain: %s", data.id, err.Error())
		}
	}

	// delete ipAdress, stopped instances doesn't have any ipAdresses
	c.MongoDB.DB.Run("jMachines", func(col *mgo.Collection) error {
		return col.UpdateId(data.id,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"status.state":      "Stopped",
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     data.reason,
			}},
		)
	})

}

func (c *Cleaner) Collect() (*Artifacts, error) {
	c.Log.Info("Collecting artifacts to be used by cleaners")
	start := time.Now().UTC()
	var wg sync.WaitGroup
	wg.Add(5)

	a := &Artifacts{
		MongodbUsers:  make(map[string]lookup.MachineDocument, 0),
		UsersMultiple: make(map[string][]lookup.MachineDocument, 0),
	}

	var collectErr error
	var err error

	go func() {
		a.IsPaid, err = c.IsPaid()
		if err != nil {
			collectErr = err
		}

		wg.Done()
	}()

	go func() {
		a.Instances = c.AWS.FetchInstances()
		wg.Done()
	}()

	go func() {
		a.AlwaysOnMachines, err = c.MongoDB.AlwaysOn()
		if err != nil {
			collectErr = err
		}
		wg.Done()
	}()

	go func() {
		a.Volumes = c.AWS.FetchVolumes()
		wg.Done()
	}()

	go func() {
		// users mapped to their machines
		users := make(map[string][]lookup.MachineDocument, 0)

		iter := func(l lookup.MachineDocument) {
			i, ok := l.Meta["instanceId"]
			if !ok {
				fmt.Println("instanceId doesn't exist")
				return
			}

			id, ok := i.(string)
			if !ok {
				fmt.Printf("MongoDB meta.instanceId is malformed %v", i)
				return
			}

			if id == "" {
				fmt.Println("instanceId is empty")
				return
			}

			a.MongodbUsers[id] = l

			// fetch duplicate users
			username := l.Credential
			machines, ok := users[username]
			if !ok {
				users[username] = []lookup.MachineDocument{l}
				return
			}

			// we found another machine
			machines = append(machines, l)
			users[username] = machines
		}

		err = c.MongoDB.Iter(iter)
		if err != nil {
			collectErr = err
		}

		// list of users with more than one machine
		for user, machines := range users {
			if len(machines) > 1 {
				a.UsersMultiple[user] = machines
			}
		}

		wg.Done()
	}()

	wg.Wait()

	// return if there is any error, it doesn't matter which one, because we
	// are going to fix all of them in any way.
	if collectErr != nil {
		return nil, collectErr
	}

	c.Log.Info("Collecting finished (total time: %s)", time.Since(start))
	return a, nil
}
