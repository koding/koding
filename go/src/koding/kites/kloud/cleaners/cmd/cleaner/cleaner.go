package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"koding/kites/kloud/provider/koding"
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
	DNS      *koding.DNS
	Domains  *koding.Domains

	Hook Hook
	Log  logging.Logger
}

type StopData struct {
	id         bson.ObjectId
	instanceId string
	domain     string
	ipAddress  string
	username   string
}

func NewCleaner(conf *Config) *Cleaner {
	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	l := lookup.NewAWS(auth)
	m := lookup.NewMongoDB(conf.MongoURL)
	dns := koding.NewDNSClient(conf.HostedZone, auth)
	domains := koding.NewDomainStorage(m.DB)
	p := lookup.NewPostgres(&lookup.PostgresConfig{
		Host:     conf.Host,
		Port:     conf.Port,
		Username: conf.Username,
		Password: conf.Password,
		DBName:   conf.DBName,
	})
	hook := Hook{
		URL:      conf.SlackURL,
		Channel:  "#reports",
		Username: "cleaner",
	}

	return &Cleaner{
		AWS:      l,
		MongoDB:  m,
		Postgres: p,
		DNS:      dns,
		Domains:  domains,
		Hook:     hook,
		Log:      logging.NewLogger("cleaner"),
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

func (c *Cleaner) Slack(msg string) error {
	return c.Hook.Post(Message{
		Channel:   c.Hook.Channel,
		Username:  c.Hook.Username,
		Text:      msg,
		IconEmoji: ":cl:",
	})
}

func (c *Cleaner) StopMachine(data *StopData) {
	if err := c.DNS.Delete(data.domain, data.ipAddress); err != nil {
		fmt.Printf("[%s] couldn't delete domain %s\n", data.id, err)
	}

	// also get all domain aliases that belongs to this machine and unset
	domains, err := c.Domains.GetByMachine(data.id.Hex())
	if err != nil {
		fmt.Printf("[%s] fetching domains for unseting err: %s\n", data.id, err.Error())
	}

	for _, ds := range domains {
		if err := c.DNS.Delete(ds.Name, data.ipAddress); err != nil {
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
				"status.reason":     "Non free user, VM is running for more than 12 hours",
			}},
		)
	})

}
