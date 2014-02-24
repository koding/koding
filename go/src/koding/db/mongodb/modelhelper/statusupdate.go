package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
)

var (
	POST_COLL = "jNewStatusUpdates"
)

func GetStatusUpdateById(id string) (*models.StatusUpdate, error) {
	statusUpdate := new(models.StatusUpdate)

	return statusUpdate, Mongo.One(POST_COLL, id, statusUpdate)
}

func UpdateStatusUpdate(s *models.StatusUpdate) error {
	query := updateByIdQuery(s.Id.Hex(), s)
	return Mongo.Run(POST_COLL, query)
}

func DeleteStatusUpdateById(id string) error {
	selector := Selector{"_id": GetObjectId(id)}
	query := func(c *mgo.Collection) error {
		return c.Remove(selector)
	}

	return Mongo.Run(POST_COLL, query)
}

func AddStatusUpdate(s *models.StatusUpdate) error {
	query := insertQuery(s)

	return Mongo.Run(POST_COLL, query)
}

func GetStatusUpdate(s Selector) (models.StatusUpdate, error) {
	su := models.StatusUpdate{}

	query := func(c *mgo.Collection) error {
		return c.Find(s).One(&su)
	}

	return su, Mongo.Run(POST_COLL, query)
}
