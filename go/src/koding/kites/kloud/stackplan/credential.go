package stackplan

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/kloud"

	"github.com/mitchellh/mapstructure"
	"gopkg.in/mgo.v2"
)

var ErrCredNotFound = errors.New("credential not found")

type CredStore interface {
	Get(identifier string, cred interface{}) error
}

type MongoCredStore struct {
	MongoDB *mongodb.MongoDB // TODO(rjeczalik): refactor modelhelper functions to not use global MongoDB
}

func (*MongoCredStore) Get(identifier string, cred interface{}) error {
	creds, err := modelhelper.GetCredentialDatasFromIdentifiers(identifier)
	if err == mgo.ErrNotFound {
		return ErrCredNotFound
	}
	if err != nil {
		return fmt.Errorf("could not fetch credential %q: %s", identifier, err)
	}

	if len(creds) == 0 {
		return ErrCredNotFound
	}

	if err := mapstructure.Decode(creds[0].Meta, cred); err != nil {
		return err
	}

	if v, ok := cred.(kloud.Validator); ok {
		if err := v.Valid(); err != nil {
			return err
		}
	}

	return nil // TODO
}
