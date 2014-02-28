package helpers

import (
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"

	"github.com/coreos/go-log/log"
	"labix.org/v2/mgo"
)

type iterOptions struct {
	Skip              int
	Limit             int
	Filter            modelhelper.Selector
	CollectionName    string
	F                 func(result interface{})
	MaxIterationCount int
	DataType          interface{}
}

func NewIterOptions(collectionName string) *iterOptions {
	return &iterOptions{
		Skip:              0,
		Limit:             1000,
		Filter:            modelhelper.Selector{},
		CollectionName:    collectionName,
		MaxIterationCount: 50,
	}
}

func Iter(mongo *mongodb.MongoDB, iterOptions *iterOptions) error {
	return mongo.Run("jAccounts", createQuery(iterOptions))
}

func createQuery(iterOptions *iterOptions) func(coll *mgo.Collection) error {
	return func(coll *mgo.Collection) error {
		// find the total count
		query := coll.Find(iterOptions.Filter)
		totalCount, err := query.Count()
		if err != nil {
			log.Error("While getting count, exiting: %v", err)
			return err
		}
		log.Info("Totaly we have %v items for operation", totalCount)

		skip := iterOptions.Skip
		// this is a starting point
		index := skip
		// this is the item count to be processed
		limit := iterOptions.Limit
		// this will be the ending point
		count := index + limit

		iteration := 0
		for {
			// if we reach to the end of the all collection, exit
			if index >= totalCount {
				log.Info("All items are processed, exiting")
				break
			}

			// this is the max re-iterating count
			if iteration == iterOptions.MaxIterationCount {
				break
			}

			// if we processed all items then exit
			if index == count {
				break
			}

			iter := query.Skip(index).Limit(count - index).Iter()

			for iter.Next(iterOptions.DataType) {
				iterOptions.F(iterOptions.DataType)
				index++
				log.Info("Index: %v", index)
			}

			if err := iter.Close(); err != nil {
				log.Error("Iteration failed: %v", err)
			}

			if iter.Timeout() {
				continue
			}

			log.Info("iter existed, starting over from %v  -- %v  item(s) are processsed on this iter", index+1, index-skip)
			iteration++
		}

		if iteration == iterOptions.MaxIterationCount {
			log.Info("Max iteration count %v reached, exiting", iteration)
		}
		log.Info("Deleted %v guest accounts on this process", index-skip)

		return nil
	}
}
