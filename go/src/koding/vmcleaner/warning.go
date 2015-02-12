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
	Name     string
	Level    int
	Interval int

	// Defines how long between emails from above level & this.
	IntervalSinceLastWarning time.Duration

	// Query that defines which user to select.
	Select bson.M

	// Action the warning will take if user isn't exempt.
	Action Action

	// Definitions of exemptions.
	Exempt []Exempt
}

func (w *Warning) Run() *Result {
	result := &Result{Warning: w.Name}

	for {
		err := w.RunSingle()
		if err != nil && !isErrNotFound(err) {
			result.Failure += 1
			continue
		}

		if isErrNotFound(err) {
			break
		}

		result.Successful += 1
	}

	return result
}

func (w *Warning) RunSingle() error {
	user, err := w.FindAndLockUser()
	if err != nil {
		return err
	}

	if err := w.Act(user); err != nil {
		return err
	}

	return w.UpdateAndReleaseUser(user.ObjectId)
}

// `FindAndLockUser` finds user with warning query and locks it
// so other workers can't work on it.
func (w *Warning) FindAndLockUser() (*models.User, error) {
	w.Select["assigned"] = bson.M{"$ne": true}

	var change = mgo.Change{
		Update: bson.M{
			"$set": bson.M{
				"inactive.assigned": true, "inactive.assignedAt": timeNow(),
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

func (w *Warning) IsUserExempt(user *models.User) (bool, error) {
	for _, exemptFn := range w.Exempt {
		yes, err := exemptFn(user, w)
		if err != nil {
			return false, nil
		}

		if yes {
			return true, nil
		}
	}

	return false, nil
}

func (w *Warning) Act(user *models.User) error {
	isExempt, err := w.IsUserExempt(user)
	if err != nil {
		return err
	}

	if !isExempt {
		return w.Action(user, w.Level)
	}

	return nil
}

// `UpdateAndReleaseUser` updates user to indicate current warning
// has been acted upon & releases user for next warning.
func (w *Warning) UpdateAndReleaseUser(userId bson.ObjectId) error {
	var query = func(c *mgo.Collection) error {
		find := bson.M{"_id": userId}
		update := bson.M{
			"$set": bson.M{
				"inactive.warning": w.Level, "inactive.modifiedAt": timeNow(),
				"inactive.warnings": bson.M{
					fmt.Sprintf("%d", w.Level): timeNow(),
				},
			},
			"$unset": bson.M{"inactive.assigned": 1, "inactive.assignedAt": 1},
		}

		return c.Update(find, update)
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

func (w *Warning) CurrentLevel() int {
	return w.Level
}

func (w *Warning) PreviousLevel() int {
	return w.Level - 1
}

func (w *Warning) NextLevel() int {
	return w.Level + 1
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func timeNow() time.Time {
	return time.Now().UTC()
}

func moreThanDaysQuery(days int) bson.M {
	return bson.M{"$lt": timeNow().Add(-time.Hour * 24 * time.Duration(days))}
}

func isErrNotFound(err error) bool {
	return err != nil && err == mgo.ErrNotFound
}
