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

	return &Cleaner{
		AWS:      l,
		MongoDB:  m,
		Postgres: p,
		DNS:      dns,
		Domains:  domains,
	}
}
