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

func GetSomeTags(s Selector, o Options) ([]models.Tag, error) {
	tags := make([]models.Tag, 0)
	query := func(c *mgo.Collection) error {
		q := c.Find(s)
		decorateQuery(q, o)
		return q.All(&tags)
	}
	return tags, mongodb.Run("jTags", query)
}

func CheckTagExistence(id string) (bool, error) {
	var exists bool
	query := checkExistence(id, &exists)
	return exists, mongodb.Run("jTags", query)
}
