package main

import (
	"koding/kites/kloud/cleaners/lookup"
	"koding/kites/kloud/provider/koding"

	"github.com/mitchellh/goamz/aws"
)

type Cleaner struct {
	AWS      *lookup.Lookup
	MongoDB  *lookup.MongoDB
	Postgres *lookup.Postgres
	DNS      *koding.DNS
	Domains  *koding.Domains

	Hook Hook
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
