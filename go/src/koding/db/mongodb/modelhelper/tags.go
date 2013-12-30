package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func GetTagById(id string) (*models.Tag, error) {
	tag := new(models.Tag)

	return tag, mongodb.One("jTags", id, tag)
}

func UpdateTag(t *models.Tag) error {
	query := func(c *mgo.Collection) error {
		return c.UpdateId(t.Id, t)
	}

	return mongodb.Run("jTags", query)
}
