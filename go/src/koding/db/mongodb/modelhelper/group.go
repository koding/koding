package modelhelper

import (
	"errors"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const GroupsCollectionName = "jGroups"

func GetGroupById(id string) (*models.Group, error) {
	group := new(models.Group)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.ObjectIdHex(id)}).One(&group)
	}

	return group, Mongo.Run(GroupsCollectionName, query)
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

		var group models.Group
		for iter.Next(&group) {
			var newGroup models.Group
			newGroup = group
			groups = append(groups, &newGroup)
		}

		return iter.Close()
	}

	return groups, Mongo.Run(GroupsCollectionName, query)
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
