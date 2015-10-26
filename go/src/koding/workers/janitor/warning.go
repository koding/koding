package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/jinzhu/now"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Warning struct {
	// ID is identifier for warning.
	ID string

	// Description is human readable description of what the warning does.
	Description string

	// PreviousWarning points to warning before current one, is required to
	// check if previous warning was run before running this one.
	PreviousWarning *Warning

	// IntervalSinceLastWarning defines how long between current and above warnings.
	IntervalSinceLastWarning time.Duration

	// Select is the query that defines which user to select.
	Select []bson.M

	// Action the warning will take if user isn't exempt.
	Action Action

	// ExemptCheckers are exemptions that will prevent the action from running.
	ExemptCheckers []*ExemptChecker

	// Throtted defines if there should be sleep time while warning is run.
	Throttled bool

	// Result is output success, failures of current run.
	Result *Result
}

func (w *Warning) Run() (*Result, error) {
	w.Result = NewResult(w.Description)

	sleepInSec, err := w.getSleepTime()
	if err != nil {
		return nil, err
	}

	for {
		if w.Throttled {
			time.Sleep(sleepInSec)
		}

		if isErrNotFound(w.RunSingle()) {
			break
		}
	}

	w.Result.EndedAt = time.Now().String()
	return w.Result, nil
}

func (w *Warning) RunSingle() error {
	user, err := w.FindAndLockUser()
	if err != nil {
		return err
	}

	isExempt, err := w.IsUserExempt(user)

	// release the user if err or if user is exempt; note how we don't
	// update the warning for user since in the future user might become
	// unexempt.
	if err != nil || isExempt {
		return w.ReleaseUser(user)
	}

	if err := w.Act(user); err != nil {
		return w.ReleaseUser(user)
	}

	return w.UpdateAndReleaseUser(user.ObjectId)
}

// FindAndLockUser finds user according to warning query and locks it.
// While this lock is held, no other worker can get access to this document.
func (w *Warning) FindAndLockUser() (*models.User, error) {
	selectQuery := w.buildSelectQuery()

	change := mgo.Change{
		Update: bson.M{
			"$set": bson.M{
				"inactive.assigned": true, "inactive.assignedAt": timeNow(),
			},
		},
		ReturnNew: true,
	}

	var user *models.User
	var query = func(c *mgo.Collection) error {
		_, err := c.Find(selectQuery).Limit(1).Apply(change, &user)
		return err
	}

	return user, modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

// IsUserExempt checks if user is exempt due to any reason. These exempt
// functions are in addition to db level checks. This is done since some
// checks can't be done in db, while others dramatically increase the
// complexity of the db query.
func (w *Warning) IsUserExempt(user *models.User) (bool, error) {
	for _, checker := range w.ExemptCheckers {
		isExempt, err := checker.IsExempt(user, w)
		if err != nil {
			return false, err
		}

		if isExempt {
			userResult := &UserResult{
				Username:      user.Name,
				LastLoginDate: user.LastLoginDate,
				ExemptReson:   checker.Name,
			}

			if w.Result != nil {
				w.Result.Exempt = append(w.Result.Exempt, userResult)
			}

			return true, nil
		}
	}

	return false, nil
}

// Act takes the specified action for the warning for the user. Only one
// action is specified for each warning since currently there's no need
// for more than one action.
func (w *Warning) Act(user *models.User) error {
	userResult := &UserResult{
		Username:      user.Name,
		LastLoginDate: user.LastLoginDate,
	}

	if w.Result != nil {
		w.Result.Successful = append(w.Result.Successful, userResult)
	}

	return w.Action(user, w.ID)
}

// UpdateAndReleaseUser updates user to indicate current warning
// has been acted upon & releases user for next warning.
func (w *Warning) UpdateAndReleaseUser(userID bson.ObjectId) error {
	warningsKey := fmt.Sprintf("inactive.warnings.%s", w.ID)

	query := func(c *mgo.Collection) error {
		find := bson.M{"_id": userID}
		update := bson.M{
			"$set": bson.M{
				"inactive.warning":    w.ID,
				"inactive.modifiedAt": timeNow(),
				warningsKey:           timeNow(),
			},
			"$unset": bson.M{"inactive.assigned": 1, "inactive.assignedAt": 1},
		}

		return c.Update(find, update)
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

// ReleaseUser releases the lock on the user so another worker can try it out,
// however it sets `modifiedAt` time so it's only processed once a day.
func (w *Warning) ReleaseUser(user *models.User) error {
	userID := user.ObjectId

	var query = func(c *mgo.Collection) error {
		find := bson.M{"_id": userID}
		update := bson.M{
			"$unset": bson.M{"inactive.assigned": 1, "inactive.assignedAt": 1},
			"$set":   bson.M{"inactive.modifiedAt": timeNow()},
		}

		return c.Update(find, update)
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

// getSleepTime returns how long to sleep between each document based on total
// number of documents. It defaults to sleeping 120 seconds when calculated
// time is too short or too long.
func (w *Warning) getSleepTime() (time.Duration, error) {
	count, err := modelhelper.CountUsersByQuery(w.buildSelectQuery())
	if err != nil || count == 0 {
		return 0, err
	}

	now := time.Now()

	timeToWork := now.Add(23*time.Hour).UnixNano() - now.UnixNano()
	sleepInSec := timeToWork / int64(count)

	if sleepInSec <= int64(120*time.Second) || sleepInSec >= int64(360*time.Second) {
		return time.Duration(120 * time.Second), nil
	}

	return time.Duration(sleepInSec), nil
}

func (w *Warning) buildSelectQuery() bson.M {
	selector := w.Select

	selector = append(selector, bson.M{"inactive.assigned": bson.M{"$ne": true}})
	selector = append(selector, bson.M{"$or": []bson.M{
		bson.M{"inactive.modifiedAt": bson.M{"$exists": false}},
		bson.M{"inactive.modifiedAt": bson.M{"$lte": now.BeginningOfDay().UTC()}},
	}})

	// mongo indexes requrie query order to be in same order of index
	// however go map doesn't preserve ordering, so we accumulate queries
	// with a slice and turn them into a map right before query time
	selectQuery := bson.M{}
	for _, query := range selector {
		for k, v := range query {
			selectQuery[k] = v
		}
	}

	return selectQuery
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func timeNow() time.Time {
	return time.Now().UTC()
}

func dayRangeQuery(days, interval int) bson.M {
	return bson.M{
		"$lt":  timeNow().Add(-time.Hour * 24 * time.Duration(days)),
		"$gte": timeNow().Add(-time.Hour * 24 * time.Duration(days+interval)),
	}
}

func moreThanDaysQuery(days int) bson.M {
	return bson.M{
		"$lt": timeNow().Add(-time.Hour * 24 * time.Duration(days)),
	}
}

func isErrNotFound(err error) bool {
	return err != nil && err == mgo.ErrNotFound
}
