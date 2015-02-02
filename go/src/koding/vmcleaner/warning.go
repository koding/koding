package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Warning struct {
	Name   string
	Level  int
	Select bson.M
	Action Action
	Exempt []Exempt
}

func (w *Warning) FindAndLockUser() (*models.User, error) {
	w.Select["assigned"] = bson.M{"$ne": true}

	var change = mgo.Change{
		Update: bson.M{
			"$set": bson.M{
				"inactive.assigned": true, "inactive.assignedAt": now().UTC(),
			},
		},
		ReturnNew: true,
	}

	var user *models.User
	var query = func(c *mgo.Collection) error {
		_, err := c.Find(w.Select).Limit(1).Apply(change, &user)
		return err
	}

	return user, modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

func (w *Warning) UpdateAndReleaseUser(userId bson.ObjectId) error {
	var query = func(c *mgo.Collection) error {
		find := bson.M{"_id": userId}
		update := bson.M{
			"$set": bson.M{
				"inactive.warning":    w.Level,
				"inactive.modifiedAt": now(),
			},
			"$unset": bson.M{"inactive.assigned": 1, "inactive.assignedAt": 1},
		}

		return c.Update(find, update)
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

func (w *Warning) FindUser() (*models.User, error) {
	var user *models.User

	query := func(c *mgo.Collection) error {
		return c.Find(w.Select).One(&user)
	}

	return user, modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

func (w *Warning) Act(userId bson.ObjectId) error {
	return nil
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func now() time.Time {
	return time.Now().UTC()
}

func moreThanDaysQuery(days int) bson.M {
	return bson.M{"$lt": now().Add(-time.Hour * 24 * time.Duration(days))}
}
