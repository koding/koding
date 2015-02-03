package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Warning struct {
	Name            string
	Level, Interval int
	Select          bson.M
	Action          Action
	Exempt          []Exempt
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
				"inactive.warning": w.Level, "inactive.modifiedAt": now(),
				"inactive.warnings": bson.M{
					fmt.Sprintf("%d", w.Level): now(),
				},
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

func (w *Warning) Act(user *models.User) error {
	if !w.IsUserExempt(user) {
		return w.Action(user, w.Level)
	}

	return nil
}

func (w *Warning) IsUserExempt(user *models.User) bool {
	for _, exemptFn := range w.Exempt {
		yes := exemptFn(user, w)
		if yes {
			return true
		}
	}

	return false
}

func (w *Warning) Run() Result {
	for {
		user, err := w.FindAndLockUser()
		if err != nil && !isErrNotFound(err) {
			handleError(err)
			continue
		}

		if isErrNotFound(err) {
			break
		}

		if !w.IsUserExempt(user) {
			err = w.Act(user)
			if err != nil {
				handleError(err)
				continue
			}
		}

		err = w.UpdateAndReleaseUser(user.ObjectId)
		if err != nil {
			handleError(err)
			continue
		}
	}

	return Result{}
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

func isErrNotFound(err error) bool {
	return err != nil && err == mgo.ErrNotFound
}
