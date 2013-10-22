package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func GetGroup(groupname string) (*models.Group, error) {
	group := new(models.Group)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"title": groupname}).One(&group)
	}

	err := mongodb.Run("jGroups", query)
	if err != nil {
		return nil, err
	}

	return group, nil
}
