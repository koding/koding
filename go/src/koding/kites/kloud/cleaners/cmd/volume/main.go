package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"os"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
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

	//  Update alwaysOn flag
	Update bool
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

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	// p := lookup.NewPostgres(&lookup.PostgresConfig{
	// 	Host:     conf.Host,
	// 	Port:     conf.Port,
	// 	Username: conf.Username,
	// 	Password: conf.Password,
	// 	DBName:   conf.DBName,
	// })
	//
	// m := lookup.NewMongoDB(conf.MongoURL)

	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	l := lookup.NewAWS(auth)

	volumes := l.FetchVolumes().GreaterThan(3)

	fmt.Println(volumes)
	fmt.Printf("Volumes greater than 3GB: %+v\n", volumes.Total())

	for _, vols := range volumes {
		for id, volume := range vols {
			fmt.Printf("[%s] %s\n", id, volume.Size)
		}
	}

	return nil
}
