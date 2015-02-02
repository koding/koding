package main

import (
	"time"

	"labix.org/v2/mgo"
)

type Inactive struct {
	Assigned               bool
	AssignedAt, ModifiedAt time.Time
}

var Warnings = []*Warning{
	FirstEmail, SecondEmail, ThirdDeleteVM,
}

// change := mgo.Change{
//   Update: bson.M{
//     "$set": bson.M{
//       "inactive.Assigned": true,
//       "inactive.AssignedAt": time.Now().UTC(),
//     },
//   },
//   ReturnNew: true,
// }

// _, err := c.Find(selector).Limit(1).Apply(change, &user)

// Update: bson.M{
//   "inactive.ModifiedAt": time.Now(),
//   "inactive.Warning.3":  time.Now(),
//   "inactive.Warning":    3,
// },

func main() {
	for _, warning := range Warnings {
		for {
			user, err := warning.FindAndLockUser()
			if err != nil && err != mgo.ErrNotFound {
				handleError(err)
				continue
			}

			if err == mgo.ErrNotFound {
				break
			}

			err = warning.Act(user)
			if err != nil {
				handleError(err)
				continue
			}

			err = warning.UpdateAndReleaseUser(user.ObjectId)
			if err != nil {
				handleError(err)
				continue
			}
		}
	}
}

func handleError(err error) {
}
