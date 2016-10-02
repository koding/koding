package credential

import (
	"fmt"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"github.com/hashicorp/go-multierror"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// mongoStore implements fetching credential data values, reading them
// from jCredentialDatas.Meta for each provided identifier.
type mongoStore struct {
	*Options
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

			if validator, ok := v.(validator); ok {
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

type MongoPerm struct {
	Acc  *models.Account
	User *models.User
	Team *models.Group
	Cred *models.Credential

	Roles []string
}

var _ Perm = (*MongoPerm)(nil)

func (p *MongoPerm) PermUser() string    { return p.User.Name }
func (p *MongoPerm) PermTeam() string    { return p.Team.Slug }
func (p *MongoPerm) PermRoles() []string { return p.Roles }

// TODO(rjeczalik): Add cache support.
type mongoDatabase struct {
	*Options
}

var _ Database = (*mongoDatabase)(nil)

func (db *mongoDatabase) Validate(f *Filter, c *Cred) (Perm, error) {
	err := f.Valid()
	if err != nil {
		return nil, err
	}

	var perm MongoPerm

	perm.Acc, err = modelhelper.GetAccount(f.User)
	if err != nil {
		return nil, models.ResError(err, "jAccount")
	}

	perm.Team, err = modelhelper.GetGroup(f.Team)
	if err != nil {
		return nil, models.ResError(err, "jGroup")
	}

	perm.User, err = modelhelper.GetUser(f.User)
	if err != nil {
		return nil, models.ResError(err, "jUser")
	}

	belongs := modelhelper.Selector{
		"targetId": perm.Acc.Id,
		"sourceId": perm.Team.Id,
		"as": bson.M{
			"$in": []string{"member"},
		},
	}

	if count, err := modelhelper.RelationshipCount(belongs); err != nil || count == 0 {
		if err == nil {
			err = fmt.Errorf("user %q does not belong to %q group", f.User, f.Team)
		}

		return nil, models.ResError(err, "jRelationships")
	}

	return nil, nil
}

func (db *mongoDatabase) Creds(f *Filter) ([]*Cred, error) {
	return nil, nil
}

func (db *mongoDatabase) SetCred(c *Cred) error {
	return nil
}
