package stackcred

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/stack"

	"github.com/hashicorp/go-multierror"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// mongoStore implements fetching credential data values, reading them
// from jCredentialDatas.Meta for each provided identifier.
type mongoStore struct {
	*StoreOptions
}

var _ Store = (*mongoStore)(nil)

func (db *mongoStore) Fetch(_ string, creds map[string]interface{}) error {
	idents := make([]string, 0, len(creds))
	for ident := range creds {
		idents = append(idents, ident)
	}

	datas, err := modelhelper.GetCredentialDatasFromIdentifiers(idents...)
	if err == mgo.ErrNotFound {
		return &NotFoundError{
			Identifiers: toIdents(creds),
		}
	}

	if err != nil {
		return &NotFoundError{
			Identifiers: toIdents(creds),
			Err:         err,
		}
	}

	m := make(map[string]*models.CredentialData, len(datas))
	for _, data := range datas {
		m[data.Identifier] = data
	}

	var missing []string
	for ident, v := range creds {
		data, ok := m[ident]
		if !ok {
			missing = append(missing, ident)
			continue
		}

		if v != nil {
			if e := db.objectBuilder().Decode(data.Meta, v); e != nil {
				missing = append(missing, ident)
				continue
			}

			if validator, ok := v.(stack.Validator); ok {
				if err := validator.Valid(); err != nil {
					missing = append(missing, ident)
					continue
				}
			}
		} else {
			creds[ident] = data.Meta
		}

		db.Log.Debug("fetched credential data for %q: %+v", ident, creds[ident])
	}

	if len(missing) != 0 {
		return &NotFoundError{
			Identifiers: missing,
		}
	}

	return nil
}

// Put updates the jCredentialDatas.meta field of an existing credential.
// It does not create new credential if it's missing by design - kloud
// does not own that resource.
func (db *mongoStore) Put(_ string, creds map[string]interface{}) error {
	var err error

	for ident, data := range creds {
		op := bson.M{
			"$set": bson.M{
				"meta": data,
			},
		}

		if e := modelhelper.UpdateCredentialData(ident, op); e != nil {
			if e == mgo.ErrNotFound {
				e = &NotFoundError{
					Identifiers: []string{ident},
				}
			}

			err = multierror.Append(err, e)
		}
	}

	return err
}
