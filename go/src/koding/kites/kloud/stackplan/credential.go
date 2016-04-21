package stackplan

import (
	"errors"
	"fmt"

	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/kloud"

	"github.com/koding/logging"
	"gopkg.in/mgo.v2"
)

var ErrCredNotFound = errors.New("credential not found")

type CredStore interface {
	Get(identifier string, cred interface{}) error
}

type MongoCredStore struct {
	MongoDB *mongodb.MongoDB // TODO(rjeczalik): refactor modelhelper functions to not use global MongoDB
	Log     logging.Logger
}

func (db *MongoCredStore) Get(identifier string, cred interface{}) error {
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

	db.Log.Debug("fetch credentials from mongo: %+v", creds[0])

	if err := modelhelper.BsonDecode(creds[0].Meta, cred); err != nil {
		return err
	}

	db.Log.Debug("decoded credentials: %# v", cred)

	if v, ok := cred.(kloud.Validator); ok {
		if err := v.Valid(); err != nil {
			return err
		}
	}

	return nil
}
