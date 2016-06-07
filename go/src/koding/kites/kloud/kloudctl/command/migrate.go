package command

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"os"
	"strings"

	"gopkg.in/mgo.v2/bson"

	"github.com/mitchellh/cli"
)

func NewMigrate() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("migrate", "Migrate user vms from solo to team")

		m := &Migrate{
			Key:         f.String("key", os.Getenv("AWS_ACCESS_KEY"), "AWS_ACCESS_KEY of user AWS account"),
			Secret:      f.String("secret", os.Getenv("AWS_SECRET_KEY"), "AWS_SECRET_KEY of user AWS account"),
			Region:      f.String("region", "us-east-1", "AWS Region to use"),
			User:        f.String("user", "", "Koding username"),
			Team:        f.String("team", "", "User team name"),
			Credential:  f.String("identifier", "", "jCredential.identifier, if empty new will be created"),
			RawMachines: f.String("machines", "", "comma-separated jMachine documents of solo vms"),
			MongoURL:    f.String("mongorul", "127.0.0.1:27017/koding", "Mongo URL of kloud database"),
			KloudKite:   f.String("kloudkite", "http://127.0.0.1:5500/kite", "Kloud kite url"),
		}

		f.action = m

		return f, nil
	}
}

type MigrateRequest struct {
	Provider    string   `json:"provider"`
	Machines    []string `json:"machines"`
	Identifier  string   `json:"identifier"`
	GroupName   string   `json:"groupName"`
	StackName   string   `json:"stackName"`
	Impersonate string   `json:"impersonate"`
}

type Migrate struct {
	Key         *string
	Secret      *string
	Region      *string
	User        *string
	Team        *string
	Credential  *string
	RawMachines *string
	MongoURL    *string
	KloudKite   *string

	Machines []string
}

func (m *Migrate) Valid() error {
	if *m.User == "" {
		return errors.New("-user is empty")
	}

	if *m.Credential == "" {
		if *m.Key == "" {
			return errors.New("-key is empty")
		}

		if *m.Secret == "" {
			return errors.New("-secret is empty")
		}

		if *m.Region == "" {
			return errors.New("-region is empty")
		}
	}

	if *m.Team == "" {
		return errors.New("-team is empty")
	}

	if *m.RawMachines == "" {
		return errors.New("-machines is empty")
	}

	m.Machines = strings.Split(*m.RawMachines, ",")

	return nil
}

func (m *Migrate) Action(args []string) error {
	if err := m.Valid(); err != nil {
		return err
	}

	c, err := kloudClient()
	if err != nil {
		return err
	}
	defer c.Close()

	modelhelper.Initialize(*m.MongoURL)
	defer modelhelper.Close()

	account, err := modelhelper.GetAccount(*m.User)
	if err != nil {
		return err
	}

	if *m.Credential == "" {
		*m.Credential = bson.NewObjectId().Hex()

		cred := &models.Credential{
			Id:         bson.NewObjectId(),
			Provider:   "aws",
			Identifier: *m.Credential,
			OriginId:   account.Id,
		}

		credData := &models.CredentialData{
			Id:         bson.NewObjectId(),
			Identifier: *m.Credential,
			OriginId:   account.Id,
			Meta: bson.M{
				"access_key": *m.Key,
				"secret_key": *m.Secret,
				"region":     *m.Region,
			},
		}

		if err := modelhelper.InsertCredential(cred, credData); err != nil {
			return err
		}

		credRelationship := &models.Relationship{
			Id:         bson.NewObjectId(),
			TargetId:   cred.Id,
			TargetName: "JCredential",
			SourceId:   account.Id,
			SourceName: "JAccount",
			As:         "owner",
		}

		if err := modelhelper.AddRelationship(credRelationship); err != nil {
			return err
		}
	}

	req := &MigrateRequest{
		Provider:    "aws",
		Machines:    m.Machines,
		Identifier:  *m.Credential,
		GroupName:   *m.Team,
		StackName:   "Migrated Stack",
		Impersonate: *m.User,
	}

	_, err = c.Tell("migrate", req)

	return err
}
