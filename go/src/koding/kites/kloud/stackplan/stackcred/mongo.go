package stackcred

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/kloud"

	"gopkg.in/mgo.v2"
)

// mongoStore implements fetching credential data values, reading them
// from jCredentialDatas.Meta for each provided identifier.
type mongoStore struct {
	*StoreOptions
}

var _ Fetcher = (*mongoStore)(nil)

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

			if validator, ok := v.(kloud.Validator); ok {
				if err := validator.Valid(); err != nil {
					missing = append(missing, ident)
					continue
				}
			}
		} else {
			creds[ident] = data.Meta
		}
	}

	if len(missing) != 0 {
		return &NotFoundError{
			Identifiers: missing,
		}
	}

	return nil
}
