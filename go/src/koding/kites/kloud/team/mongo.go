package team

import (
	"fmt"
	"strconv"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2/bson"
)

// adapter is a private interface used as an adapter for mongo singleton.
type adapter interface {
	GetAccount(username string) (*models.Account, error)          // AccountsColl
	RelationshipCount(selector modelhelper.Selector) (int, error) // RelationshipColl
	GetAllRelationships(selector modelhelper.Selector) ([]models.Relationship, error)
	GetGroup(slugName string) (*models.Group, error)
	GetGroupsByIds(ids ...bson.ObjectId) ([]*models.Group, error) // GroupsCollectionName
}

// MongoDatabase implements Database interface. This type is responsible for
// communicating with Mongo database.
type MongoDatabase struct {
	adapter adapter
}

var _ Database = (*MongoDatabase)(nil)

// NewMongoDatabase creates a new MongoDatabase instance.
func NewMongoDatabase() *MongoDatabase {
	return &MongoDatabase{
		adapter: modelHelperAdapter{}, // use modelhelper package's singleton.
	}
}

// Teams returns all teams stored in MongoDB database that matches a given
// filter.
func (m *MongoDatabase) Teams(f *Filter) ([]*Team, error) {
	if f == nil {
		f = &Filter{}
	}

	accountDB, err := m.adapter.GetAccount(f.Username)
	if err != nil {
		return nil, models.ResError(err, modelhelper.AccountsColl)
	}

	if f.Teamname != "" {
		return m.fetchOne(accountDB.Id, f.Username, f.Teamname)
	} else {
		return m.fetchAll(accountDB.Id)
	}
}

// fetchOne returns only specified team.
func (m *MongoDatabase) fetchOne(accID bson.ObjectId, user, teamSlug string) ([]*Team, error) {
	groupDB, err := m.adapter.GetGroup(teamSlug)
	if err != nil {
		return nil, models.ResError(err, modelhelper.GroupsCollectionName)
	}

	belongs := modelhelper.Selector{
		"targetId": accID,
		"sourceId": groupDB.Id,
		"as":       "member",
	}

	count, err := m.adapter.RelationshipCount(belongs)
	if err == nil && count == 0 {
		err = fmt.Errorf("user %q does not belong to %q group", user, teamSlug)
	}
	if err != nil {
		return nil, models.ResError(err, modelhelper.RelationshipColl)
	}

	return groups2teams(groupDB), nil
}

// fetchOne returns all user's teams.
func (m *MongoDatabase) fetchAll(accID bson.ObjectId) ([]*Team, error) {
	belongs := modelhelper.Selector{
		"targetId":   accID,
		"sourceName": "JGroup",
		"as":         "member",
	}

	relsDB, err := m.adapter.GetAllRelationships(belongs)
	if err != nil {
		return nil, models.ResError(err, modelhelper.RelationshipColl)
	}

	ids := make([]bson.ObjectId, len(relsDB))
	for i := range relsDB {
		ids[i] = relsDB[i].SourceId
	}

	groupsDB, err := modelhelper.GetGroupsByIds(ids...)
	if err != nil {
		return nil, models.ResError(err, modelhelper.GroupsCollectionName)
	}

	return groups2teams(groupsDB...), nil
}

func groups2teams(groups ...*models.Group) []*Team {
	teams := make([]*Team, 0, len(groups))
	for _, group := range groups {
		if group == nil || group.Slug == "koding" {
			continue
		}

		// Filter teams that have empty subscription.
		if group.Payment.Subscription.ID == "" {
			continue
		}

		members, _ := group.Counts["members"].(int)
		teams = append(teams, &Team{
			Name:         group.Title,
			Slug:         group.Slug,
			Members:      strconv.Itoa(members),
			Privacy:      group.Privacy,
			Subscription: group.Payment.Subscription.Status,
		})
	}

	return teams
}
