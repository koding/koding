package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
)

func GetTagById(id string) (*models.Tag, error) {
	tag := new(models.Tag)

	return tag, Mongo.One("jTags", id, tag)
}

func UpdateTag(t *models.Tag) error {
	query := func(c *mgo.Collection) error {
		return c.UpdateId(t.Id, t)
	}

	return Mongo.Run("jTags", query)
}

func GetSomeTags(s Selector, o Options) ([]models.Tag, error) {
	tags := make([]models.Tag, 0)
	query := func(c *mgo.Collection) error {
		q := c.Find(s)
		decorateQuery(q, o)
		return q.All(&tags)
	}
	return tags, Mongo.Run("jTags", query)
}

func CheckTagExistence(id string) (bool, error) {
	var exists bool
	query := checkExistence(id, &exists)
	return exists, Mongo.Run("jTags", query)
}

func GetTag(s Selector, o Options) (*models.Tag, error) {
	tag := new(models.Tag)

	query := func(c *mgo.Collection) error {
		q := c.Find(s)
		decorateQuery(q, o)
		return q.One(tag)
	}

	return tag, Mongo.Run("jTags", query)
}

func GetTagIter(s Selector, o Options) *mgo.Iter {
	query := func(c *mgo.Collection) *mgo.Query {
		q := c.Find(s)
		decorateQuery(q, o)
		return q
	}

	return Mongo.GetIter("jTags", query)
}
