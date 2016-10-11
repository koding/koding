package credential

import (
	"errors"
	"fmt"
	"time"

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
	AccModel   *models.Account
	UserModel  *models.User
	TeamModel  *models.Group
	CredModel  *models.Credential
	CredGroups []bson.ObjectId

	RoleNames []string
	Member    bool
}

var _ Perm = (*MongoPerm)(nil)

func (p *MongoPerm) User() string    { return p.UserModel.Name }
func (p *MongoPerm) Team() string    { return p.TeamModel.Slug }
func (p *MongoPerm) Roles() []string { return p.RoleNames }

type mongoDatabase struct {
	*Options
}

var _ Database = (*mongoDatabase)(nil)

func (db *mongoDatabase) Validate(f *Filter, c *Cred) (Perm, error) {
	log := db.log().New("Validate")

	if err := f.Valid(); err != nil {
		return nil, err
	}

	if f.Matches(c.Perm) {
		return c.Perm, nil
	}

	perm := extractMongoPerm(f, c)

	if err := db.fetchModels(f, perm); err != nil {
		return nil, err
	}

	belongs := modelhelper.Selector{
		"targetId": perm.CredModel.Id,
		"sourceId": bson.M{
			"$in": perm.CredGroups,
		},
		"as": bson.M{"$in": perm.Roles},
	}

	log.Debug("testing relationship for %+v", belongs)

	if count, err := modelhelper.RelationshipCount(belongs); err != nil || count == 0 {
		if err == nil {
			err = fmt.Errorf("user %q has no access to %q credential", f.Username, c.Ident)
		}

		return nil, models.ResError(err, "jRelationship")
	}

	if c.Perm == nil {
		c.Perm = perm
	}

	return perm, nil
}

func (db *mongoDatabase) fetchModels(f *Filter, perm *MongoPerm) (err error) {
	log := db.Log.New("fetchModels")

	if perm.AccModel == nil {
		log.Debug("fetching %q account", f.Username)

		perm.AccModel, err = modelhelper.GetAccount(f.Username)
		if err != nil {
			return models.ResError(err, "jAccount")
		}

		perm.CredGroups = append(perm.CredGroups, perm.AccModel.Id)
	}

	if perm.UserModel == nil {
		log.Debug("fetching %q user", f.Username)

		perm.UserModel, err = modelhelper.GetUser(f.Username)
		if err != nil {
			return models.ResError(err, "jUser")
		}
	}

	if f.Teamname != "" {
		if perm.TeamModel == nil {
			log.Debug("fetching %q team", f.Teamname)

			perm.TeamModel, err = modelhelper.GetGroup(f.Teamname)
			if err != nil {
				return models.ResError(err, "jGroup")
			}

			perm.CredGroups = append(perm.CredGroups, perm.TeamModel.Id)
		}

		if !perm.Member {
			belongs := modelhelper.Selector{
				"targetId": perm.AccModel.Id,
				"sourceId": perm.TeamModel.Id,
				"as":       "member",
			}

			log.Debug("testing relationship for %+v", belongs)

			if count, err := modelhelper.RelationshipCount(belongs); err != nil || count == 0 {
				if err == nil {
					err = fmt.Errorf("user %q does not belong to %q group", f.Username, f.Teamname)
				}

				return models.ResError(err, "jRelationship")
			}

			perm.Member = true
		}
	}

	if perm.CredModel == nil {
		log.Debug("fetching %q credential", f.Ident)

		perm.CredModel, err = modelhelper.GetCredential(f.Ident)
		if err != nil {
			return models.ResError(err, "jCredential")
		}
	}

	return nil
}

func (db *mongoDatabase) Creds(f *Filter) ([]*Cred, error) {
	log := db.log().New("Creds")

	if err := f.Valid(); err != nil {
		return nil, err
	}

	acc, err := modelhelper.GetAccount(f.Username)
	if err != nil {
		return nil, models.ResError(err, "jAccount")
	}

	user, err := modelhelper.GetUser(f.Username)
	if err != nil {
		return nil, models.ResError(err, "jUser")
	}

	teams := make(map[bson.ObjectId]*models.Group)

	if f.Teamname != "" {
		team, err := modelhelper.GetGroup(f.Teamname)
		if err != nil {
			return nil, models.ResError(err, "jGroup")
		}

		belongs := modelhelper.Selector{
			"targetId": acc.Id,
			"sourceId": team.Id,
			"as":       "member",
		}

		if count, err := modelhelper.RelationshipCount(belongs); err != nil || count == 0 {
			if err == nil {
				err = fmt.Errorf("user %q does not belong to %q group", f.Username, f.Teamname)
			}

			return nil, models.ResError(err, "jRelationship")
		}

		teams[team.Id] = team
	} else {
		belongs := modelhelper.Selector{
			"targetId":   acc.Id,
			"sourceName": "JGroup",
			"as":         "member",
		}

		rels, err := modelhelper.GetAllRelationships(belongs)
		if err != nil {
			return nil, models.ResError(err, "jRelationship")
		}

		for _, rel := range rels {
			team, err := modelhelper.GetGroupById(rel.SourceId.Hex())
			if err != nil {
				return nil, models.ResError(err, "jGroup")
			}

			teams[team.Id] = team
		}
	}

	var creds []*Cred

	// Fetch credentials that user owns.
	ownerOnly := modelhelper.Selector{
		"targetName": "JCredential",
		"sourceId":   acc.Id,
		"as":         "owner",
	}

	if err := db.fetchCreds(f, acc, user, nil, ownerOnly, &creds); err != nil {
		return nil, err
	}

	log.Debug("fetched user owned credentials: %+v", creds)

	if len(teams) != 0 {
		ids := make([]bson.ObjectId, 0, len(teams))

		for id := range teams {
			ids = append(ids, id)
		}

		// Fetch credentials that user has access to.
		userOnly := modelhelper.Selector{
			"targetName": "JCredential",
			"sourceId": bson.M{
				"$in": ids,
			},
			"as": "user",
		}

		if err := db.fetchCreds(f, acc, user, teams, userOnly, &creds); err != nil {
			return nil, err
		}

		log.Debug("fetch user shared credentials: %+v", creds)
	}

	return creds, nil
}

func (db *mongoDatabase) fetchCreds(f *Filter, acc *models.Account, user *models.User,
	teams map[bson.ObjectId]*models.Group, belongs modelhelper.Selector, creds *[]*Cred) error {

	db.log().Debug("fetching credentials for %+v", belongs)

	rels, err := modelhelper.GetAllRelationships(belongs)
	if err != nil && err != mgo.ErrNotFound {
		return models.ResError(err, "jRelationship")
	}

	for _, rel := range rels {
		cred, err := modelhelper.GetCredentialByID(rel.TargetId)
		if err == mgo.ErrNotFound {
			// dangling jRelationship, ignore
			continue
		}
		if err != nil {
			return models.ResError(err, "jCredential")
		}

		if f.Provider != "" && cred.Provider != f.Provider {
			// provider does not contains, filter out
			continue
		}

		c := &Cred{
			Ident:    cred.Identifier,
			Provider: cred.Provider,
			Title:    cred.Title,
			Perm: &MongoPerm{
				AccModel:  acc,
				UserModel: user,
				CredModel: cred,
				RoleNames: UserRole,
			},
		}

		db.log().Debug("fetched %+v", c)

		if team, ok := teams[rel.SourceId]; ok {
			c.Team = team.Slug
			c.Perm.(*MongoPerm).TeamModel = team
		}

		*creds = append(*creds, c)
	}

	return nil
}

func (db *mongoDatabase) SetCred(c *Cred) error {
	f, ok := c.Perm.(*Filter)
	if !ok {
		return errors.New("invalid credential permission")
	}

	perm, err := db.Validate(f, c)
	if err == nil {
		c.Perm = perm
		return nil
	}

	if !models.IsNotFound(err, "jCredential") {
		return err
	}

	mPerm, ok := perm.(*MongoPerm)
	if !ok {
		return fmt.Errorf("unable to create credential: %s", err)
	}

	if mPerm.AccModel == nil {
		return fmt.Errorf("unable to create credential: missing %q account", f.Username)
	}

	now := time.Now().UTC()

	if c.Title == "" {
		c.Title = mPerm.UserModel.Name + " " + now.String()
	}

	mPerm.CredModel = &models.Credential{
		Id:          bson.NewObjectId(),
		Provider:    c.Provider,
		Identifier:  c.Ident,
		Title:       c.Title,
		OriginId:    mPerm.AccModel.Id,
		Verified:    false,
		AccessLevel: "private",
		Meta: &models.CredentialMeta{
			CreatedAt:  now,
			ModifiedAt: now,
		},
	}

	if err := modelhelper.CreateCredential(mPerm.CredModel); err != nil {
		return err
	}

	rel := &models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   mPerm.CredModel.Id,
		TargetName: "JCredential",
		SourceId:   mPerm.AccModel.Id,
		SourceName: "JAccount",
		As:         "owner",
		TimeStamp:  now,
	}

	if err := modelhelper.AddRelationship(rel); err != nil {
		return err
	}

	c.Perm = mPerm

	return nil
}

func extractMongoPerm(f *Filter, c *Cred) *MongoPerm {
	perm := &MongoPerm{
		RoleNames: f.RoleNames,
	}

	if len(perm.RoleNames) == 0 {
		perm.RoleNames = DefaultRoles
	}

	switch mPerm := c.Perm.(type) {
	case *MongoPerm:
		if mPerm.User() != f.Username {
			break
		}

		// If cached user containses the requested one,
		// we don't need to query MongoDB again,
		// we just reuse the existing model.
		perm.AccModel = mPerm.AccModel
		perm.UserModel = mPerm.UserModel
		perm.CredGroups = append(perm.CredGroups, perm.AccModel.Id)

		if mPerm.Team() != f.Teamname {
			break
		}

		// If cached team containses the requested one,
		// we don't need to query MongoDB again,
		// we just reuse the existing model.
		//
		// Since both user and team are already
		// fetched from MongoDB, it means they
		// were validated for a member relationship,
		// we don't need to test it again as well.
		perm.TeamModel = mPerm.TeamModel
		perm.Member = true
		perm.CredGroups = append(perm.CredGroups, perm.TeamModel.Id)
	}

	return perm
}
