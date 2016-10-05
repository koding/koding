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
	Acc  *models.Account
	User *models.User
	Team *models.Group
	Cred *models.Credential

	Roles  []string
	Member bool
}

var _ Perm = (*MongoPerm)(nil)

func (p *MongoPerm) PermUser() string    { return p.User.Name }
func (p *MongoPerm) PermTeam() string    { return p.Team.Slug }
func (p *MongoPerm) PermRoles() []string { return p.Roles }

type mongoDatabase struct {
	*Options
}

var _ Database = (*mongoDatabase)(nil)

func (db *mongoDatabase) Validate(f *Filter, c *Cred) (Perm, error) {
	log := db.log().New("Validate")

	err := f.Valid()
	if err != nil {
		return nil, err
	}

	if f.Team == "" {
		return nil, errors.New("validate: invalid empty team name")
	}

	perm := &MongoPerm{
		Roles: f.Roles,
	}

	if len(perm.Roles) == 0 {
		log.Debug("using DefaultRoles for filter=%+v, cred=%+v", f, c)

		perm.Roles = DefaultRoles
	}

	log.Debug("testing whether c.Perm=%#v matches c=%#v", c.Perm, c)

	switch cached := c.Perm.(type) {
	case nil:
	case *Filter:
		// ignore
	case *MongoPerm:
		if cached.PermUser() != f.User {
			c.Perm = nil
			break
		}

		// If cached user matches the requested one,
		// we don't need to query MongoDB again,
		// we just reuse the existing model.
		perm.Acc = cached.Acc
		perm.User = cached.User

		if cached.PermTeam() != f.Team {
			c.Perm = nil
			break
		}

		// If cached team matches the requested one,
		// we don't need to query MongoDB again,
		// we just reuse the existing model.
		//
		// Since both user and team are already
		// fetched from MongoDB, it means they
		// were validated for a member relationship,
		// we don't need to test it again as well.
		perm.Team = cached.Team
		perm.Member = true

		if !match(cached.PermRoles(), perm.Roles) {
			c.Perm = nil
			break
		}

		return c.Perm, nil
	default:
		if cached.PermUser() != f.User {
			break
		}

		if cached.PermTeam() != f.Team {
			break
		}

		if !match(cached.PermRoles(), perm.Roles) {
			break
		}

		return c.Perm, nil
	}

	if perm.Acc == nil {
		log.Debug("fetching %q account", f.User)

		perm.Acc, err = modelhelper.GetAccount(f.User)
		if err != nil {
			return nil, models.ResError(err, "jAccount")
		}
	}

	if perm.User == nil {
		log.Debug("fetching %q user", f.User)

		perm.User, err = modelhelper.GetUser(f.User)
		if err != nil {
			return nil, models.ResError(err, "jUser")
		}
	}

	if perm.Team == nil {
		log.Debug("fetching %q team", f.Team)

		perm.Team, err = modelhelper.GetGroup(f.Team)
		if err != nil {
			return nil, models.ResError(err, "jGroup")
		}
	}

	if !perm.Member {
		belongs := modelhelper.Selector{
			"targetId": perm.Acc.Id,
			"sourceId": perm.Team.Id,
			"as":       "member",
		}

		log.Debug("testing relationship for %+v", belongs)

		if count, err := modelhelper.RelationshipCount(belongs); err != nil || count == 0 {
			if err == nil {
				err = fmt.Errorf("user %q does not belong to %q group", f.User, f.Team)
			}

			return nil, models.ResError(err, "jRelationship")
		}

		perm.Member = true
	}

	if perm.Cred == nil {
		log.Debug("fetching %q credential", c.Ident)

		perm.Cred, err = modelhelper.GetCredential(c.Ident)
		if err != nil {
			return perm, models.ResError(err, "jCredential")
		}
	}

	belongs := modelhelper.Selector{
		"targetId": perm.Cred.Id,
		"sourceId": bson.M{
			"$in": []bson.ObjectId{perm.Acc.Id, perm.Team.Id},
		},
		"as": bson.M{"$in": perm.Roles},
	}

	log.Debug("testing relationship for %+v", belongs)

	if count, err := modelhelper.RelationshipCount(belongs); err != nil || count == 0 {
		if err == nil {
			err = fmt.Errorf("user %q has no access to %q credential", f.User, c.Ident)
		}

		return nil, models.ResError(err, "jRelationship")
	}

	if c.Perm == nil {
		c.Perm = perm
	}

	return perm, nil
}

func (db *mongoDatabase) Creds(f *Filter) ([]*Cred, error) {
	log := db.log().New("Creds")

	if err := f.Valid(); err != nil {
		return nil, err
	}

	acc, err := modelhelper.GetAccount(f.User)
	if err != nil {
		return nil, models.ResError(err, "jAccount")
	}

	user, err := modelhelper.GetUser(f.User)
	if err != nil {
		return nil, models.ResError(err, "jUser")
	}

	teams := make(map[bson.ObjectId]*models.Group)

	if f.Team != "" {
		team, err := modelhelper.GetGroup(f.Team)
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
				err = fmt.Errorf("user %q does not belong to %q group", f.User, f.Team)
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
			// provider does not match, filter out
			continue
		}

		c := &Cred{
			Ident:    cred.Identifier,
			Provider: cred.Provider,
			Title:    cred.Title,
			Perm: &MongoPerm{
				Acc:   acc,
				User:  user,
				Cred:  cred,
				Roles: UserRole,
			},
		}

		db.log().Debug("fetched %+v", c)

		if team, ok := teams[rel.SourceId]; ok {
			c.Team = team.Slug
			c.Perm.(*MongoPerm).Team = team
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

	if mPerm.Acc == nil {
		return fmt.Errorf("unable to create credential: missing %q account", f.User)
	}

	if mPerm.Team == nil {
		return fmt.Errorf("unable to create credential: missing %q team", f.Team)
	}

	now := time.Now().UTC()

	mPerm.Cred = &models.Credential{
		Id:          bson.NewObjectId(),
		Provider:    c.Provider,
		Identifier:  c.Ident,
		Title:       c.Title,
		OriginId:    mPerm.Acc.Id,
		Verified:    false,
		AccessLevel: "private",
		Meta: &models.CredentialMeta{
			CreatedAt:  now,
			ModifiedAt: now,
		},
	}

	if err := modelhelper.CreateCredential(mPerm.Cred); err != nil {
		return err
	}

	rel := &models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   mPerm.Cred.Id,
		TargetName: "JCredential",
		SourceId:   mPerm.Acc.Id,
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

func match(existing, expected []string) bool {
	rolesMatch := true

	for _, want := range expected {
		var found bool

		for _, got := range existing {
			if want == got {
				found = true
				break
			}
		}

		if !found {
			rolesMatch = false
			break
		}
	}

	return rolesMatch
}
