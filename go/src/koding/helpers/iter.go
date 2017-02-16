package helpers

import (
	"errors"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"

	"github.com/koding/logging"
	"gopkg.in/mgo.v2"
)

// iterOptions holds the related config parameters for Iter operation
type iterOptions struct {
	// Starting offset
	Skip int

	// Ending point, iter count
	Limit int

	// Filter for limiting the result set
	Filter modelhelper.Selector

	Sort []string

	// Iteration collection
	CollectionName string

	// Iteration function, all results will be passed to this function
	F func(result interface{}) error

	// Sometimes iteration can timeout, this is retry count
	RetryCount int

	// Data object itself for marshalling the result
	Result interface{}

	// logging for iteration
	Log logging.Logger
}

// NewIterOptions Sets the default values for iterOptions
func NewIterOptions() *iterOptions {
	return &iterOptions{
		Skip:       0,
		Limit:      1000,
		Filter:     modelhelper.Selector{},
		RetryCount: 50,
		Log:        logging.NewCustom("Iter", false),
	}
}

// Iter accepts mongo and iterOptions and runs the query
func Iter(mongo *mongodb.MongoDB, iterOptions *iterOptions) error {
	if iterOptions.CollectionName == "" {
		return errors.New("Collection name is not set")
	}

	if iterOptions.F == nil {
		return errors.New("Iteration function is not given")
	}
	if iterOptions.Result == nil {
		return errors.New("Datatype is not given")
	}

	return mongo.Run(iterOptions.CollectionName, createQuery(iterOptions))
}

// createQuery creates mongo query for iteration
func createQuery(iterOptions *iterOptions) func(coll *mgo.Collection) error {
	return func(coll *mgo.Collection) error {
		// find the total count
		query := coll.Find(iterOptions.Filter)
		totalCount, err := query.Count()
		if err != nil {
			iterOptions.Log.Error("While getting count, exiting: %v", err)
			return err
		}
		iterOptions.Log.Info("Totaly we have %v items for operation", totalCount)

		skip := iterOptions.Skip   // this is a starting point
		index := skip              // this is the item count to be processed
		limit := iterOptions.Limit // this will be the ending point
		if limit == 0 {
			// if limit is not given process all the records
			limit = totalCount
		}

		count := index + limit // total count
		sort := iterOptions.Sort

		if len(sort) == 0 {
			sort = []string{"$natural"}
		}

		iteration := 0
		for {
			// if we reach to the end of the all collection, exit
			if index >= totalCount {
				iterOptions.Log.Info("All items are processed, exiting")
				break
			}

			// this is the max re-iterating count
			if iteration == iterOptions.RetryCount {
				break
			}

			// if we processed all items then exit
			if index == count {
				break
			}

			iter := query.Sort(sort...).Skip(index).Limit(count - index).Iter()

			for iter.Next(iterOptions.Result) {
				if err := iterOptions.F(iterOptions.Result); err != nil {
					return err
				}
				index++
				iterOptions.Log.Debug("Index: %v", index)
			}

			if err := iter.Close(); err != nil {
				iterOptions.Log.Error("Iteration failed: %v", err)
			}

			if iter.Timeout() {
				continue
			}

			iterOptions.Log.Info("iter existed, starting over from %v  -- %v  item(s) are processsed on this iter", index+1, index-skip)
			iteration++
		}

		if iteration == iterOptions.RetryCount {
			iterOptions.Log.Info("Max iteration count %v reached, exiting", iteration)
		}
		iterOptions.Log.Info("Deleted %v items on this process", index-skip)

		return nil
	}
}
