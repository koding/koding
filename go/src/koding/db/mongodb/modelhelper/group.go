package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func GetGroupById(id string) (*models.Group, error) {
	group := new(models.Group)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.ObjectIdHex(id)}).One(&group)
	}

	return group, Mongo.Run("jGroups", query)
}

func GetGroup(slugName string) (*models.Group, error) {
	group := new(models.Group)

	query := func(c *mgo.Collection) error {
		return c.Find(Selector{"slug": slugName}).One(&group)
	}

	return group, Mongo.Run("jGroups", query)
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

	return count > 0, Mongo.Run("jGroups", query)
}

func UpdateGroup(g *models.Group) error {
	query := updateByIdQuery(g.Id.Hex(), g)
	return Mongo.Run("jGroups", query)
}

func UpdateGroupPartial(selector, options Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Update(selector, options)
	}

	return Mongo.Run("jGroups", query)
}
