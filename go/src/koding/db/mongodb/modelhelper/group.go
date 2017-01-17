package modelhelper

import (
	"errors"
	"net"
	"net/url"
	"strings"
	"time"

	"koding/db/models"
	"koding/kites/kloud/utils"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const GroupsCollectionName = "jGroups"

func GetGroupById(id string) (*models.Group, error) {
	var group models.Group

	return &group, Mongo.Run(GroupsCollectionName, func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.ObjectIdHex(id)}).One(&group)
	})
}

// GetGroupsByIds returns groups by their given IDs
func GetGroupsByIds(ids ...bson.ObjectId) ([]*models.Group, error) {
	var groups []*models.Group

	return groups, Mongo.Run(GroupsCollectionName, func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": ids}}).All(&groups)
	})
}

// GetGroupFieldsByIds retrieves a slice of groups matching the given ids and
// limited to the specified fields.
func GetGroupFieldsByIds(ids []string, fields []string) ([]*models.Group, error) {
	groups := []*models.Group{}

	objectIds := make([]bson.ObjectId, len(ids))
	for i, id := range ids {
		objectIds[i] = bson.ObjectIdHex(id)
	}

	selects := bson.M{}
	for _, f := range fields {
		selects[f] = 1
	}

	query := func(c *mgo.Collection) error {
		iter := c.Find(bson.M{
			"_id": bson.M{"$in": objectIds},
		}).Select(selects).Iter()

		for g := new(models.Group); iter.Next(g); g = new(models.Group) {
			groups = append(groups, g)
		}

		return iter.Close()
	}

	return groups, Mongo.Run(GroupsCollectionName, query)
}

var lookupGroupFields = bson.M{
	"registerUrl": 1,
	"queryString": 1,
	"ipAddress":   1,
	"groups.id":   1,
}

type LookupGroupOptions struct {
	KiteID      string
	ClientURL   string
	Environment string
	Username    string
}

// GetGroupForKite reverse looks up a team name for the given kiteID
// by looking up a kiteID among jMachine.queryString fields.
//
// TODO(rjeczalik): This method does client-side filtering,
// due to lack of indexes on the following fields:
//
//   - registerUrl
//   - queryString
//   - ipAddress
//
// After the indexes are in place, the LookupGroup should
// be reworked to look up on jMachine.queryString only.
func LookupGroup(opts *LookupGroupOptions) (*models.Group, error) {
	var m []struct {
		RegisterURL string `bson:"registerUrl"`
		QueryString string `bson:"queryString"`
		IPAddress   string `bson:"ipAddress"`
		Groups      []struct {
			ID bson.ObjectId `bson:"id"`
		} `bson:"groups"`
	}

	id, err := GetUserID(opts.Username)
	if err != nil {
		return nil, err
	}

	fn := func(c *mgo.Collection) error {
		return c.Find(bson.M{"users.id": id}).Select(lookupGroupFields).All(&m)
	}

	if err := Mongo.Run(MachinesColl, fn); err != nil && err != mgo.ErrNotFound {
		return nil, err
	}

	// Look for questString.
	if qs, err := utils.QueryString(opts.KiteID); err == nil && qs != "" {
		for i := range m {
			if len(m[i].Groups) == 0 {
				continue
			}

			if m[i].QueryString == qs {
				return GetGroupById(m[i].Groups[0].ID.Hex())
			}
		}
	}

	if host, err := parseHost(opts.ClientURL); err == nil && host != "" {
		// Look up for ipAddress.
		for i := range m {
			if len(m[i].Groups) == 0 {
				continue
			}

			mHost := m[i].IPAddress
			if host, _, err := net.SplitHostPort(mHost); err == nil {
				mHost = host
			}

			if mHost == host {
				return GetGroupById(m[i].Groups[0].ID.Hex())
			}
		}

		// Look up for registerUrl.
		for i := range m {
			if len(m[i].Groups) == 0 {
				continue
			}

			if mHost, err := parseHost(m[i].RegisterURL); err == nil && mHost == host {
				return GetGroupById(m[i].Groups[0].ID.Hex())
			}
		}
	}

	// KD does not have a jMachine document (TODO - #8514), instead
	// we return a group in a best-effor manner - we look up
	// the most recently accessed session for the user,
	// and give the the group attached to it.
	switch strings.ToLower(opts.Environment) {
	case "managed", "devmanaged":
		session, err := GetMostRecentSession(opts.Username)
		if err != nil {
			return nil, err
		}

		return GetGroup(session.GroupName)
	}

	return nil, mgo.ErrNotFound
}

func parseHost(s string) (string, error) {
	if s == "" {
		return "", errors.New("modelhelper: empty url")
	}

	u, err := url.Parse(s)
	if err != nil {
		return "", err
	}

	if host, _, err := net.SplitHostPort(u.Host); err == nil {
		u.Host = host
	}

	return u.Host, nil
}

func GetGroup(slugName string) (*models.Group, error) {
	group := new(models.Group)

	query := func(c *mgo.Collection) error {
		return c.Find(Selector{"slug": slugName}).One(&group)
	}

	return group, Mongo.Run(GroupsCollectionName, query)
}

func GetGroupOwner(group *models.Group) (*models.Account, error) {
	if !group.Id.Valid() {
		return nil, errors.New("group id is not valid")
	}

	rel, err := GetRelationship(Selector{
		"sourceId": group.Id,
		"as":       "owner",
	})

	if err != nil {
		return nil, err
	}

	return GetAccountById(rel.TargetId.Hex())
}

func RemoveGroup(id bson.ObjectId) error {
	return RemoveDocument(GroupsCollectionName, id)
}

func CheckGroupExistence(groupname string) (bool, error) {
	var count int
	query := func(c *mgo.Collection) error {
		var err error
		count, err = c.Find(Selector{"slug": groupname}).Count()
		if err != nil {
			return err
		}
		return nil
	}

	return count > 0, Mongo.Run(GroupsCollectionName, query)
}

func UpdateGroup(g *models.Group) error {
	query := updateByIdQuery(g.Id.Hex(), g)
	return Mongo.Run(GroupsCollectionName, query)
}

func UpdateGroupPartial(selector, options Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Update(selector, options)
	}

	return Mongo.Run(GroupsCollectionName, query)
}

func CreateGroup(m *models.Group) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(m)
	}

	return Mongo.Run(GroupsCollectionName, query)
}

func MakeAdmin(accountId, groupId bson.ObjectId) error {
	r := &models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   accountId,
		TargetName: "JAccount",
		SourceId:   groupId,
		SourceName: "JGroup",
		As:         "admin",
		TimeStamp:  time.Now().UTC(),
	}

	return AddRelationship(r)
}
