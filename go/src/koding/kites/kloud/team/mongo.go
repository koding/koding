package team

import (
	"fmt"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	mgo "gopkg.in/mgo.v2"
)

// adapter is a private interface used as an adapter for mongo singleton.
type adapter interface {
	GetGroup(slugName string) (*models.Group, error)
	IsParticipant(username, groupName string) (bool, error)
	FetchAccountGroups(username string) (groups []*models.Group, err error)
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

	if f.Slug != "" {
		return m.fetchOne(f.Username, f.Slug)
	}
	return m.fetchAll(f.Username)
}

// fetchOne returns only specified team.
func (m *MongoDatabase) fetchOne(user, slug string) ([]*Team, error) {
	group, err := m.adapter.GetGroup(slug)
	if err == mgo.ErrNotFound {
		return []*Team{}, nil
	} else if err != nil {
		return nil, models.ResError(err, modelhelper.GroupsCollectionName)
	}

	switch participant, err := m.adapter.IsParticipant(user, slug); {
	case err != nil:
		return nil, models.ResError(err, modelhelper.RelationshipColl)
	case !participant:
		return nil, fmt.Errorf("user %q does not belong to %q group", user, slug)
	}

	return groups2teams(group), nil
}

// fetchOne returns all user's teams.
func (m *MongoDatabase) fetchAll(user string) ([]*Team, error) {
	groups, err := m.adapter.FetchAccountGroups(user)
	if err != nil && err != mgo.ErrNotFound {
		return nil, models.ResError(err, modelhelper.GroupsCollectionName)
	}

	return groups2teams(groups...), nil
}

func groups2teams(groups ...*models.Group) []*Team {
	teams := make([]*Team, 0, len(groups))
	for _, group := range groups {
		if group == nil || group.Slug == "koding" {
			continue
		}

		// Filter teams that have empty subscription.
		if group.Payment.Subscription.Status == "" {
			continue
		}

		teams = append(teams, &Team{
			Name:      group.Title,
			Slug:      group.Slug,
			Privacy:   group.Privacy,
			SubStatus: group.Payment.Subscription.Status,
		})
	}

	return teams
}
