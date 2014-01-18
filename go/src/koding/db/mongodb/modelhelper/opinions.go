package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func DeleteOpinion(selector Selector) error {
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(selector)
		return err
	}

	return mongodb.Run("jOpinions", query)
}

func CheckOpinionExistence(id string) (bool, error) {
	var exists bool
	query := checkExistence(id, &exists)
	return exists, mongodb.Run("jOpinions", query)
}

func GetOpinionById(id string) (*models.Post, error) {
	opinion := new(models.Post)
	return opinion, mongodb.One("jOpinions", id, opinion)
}
