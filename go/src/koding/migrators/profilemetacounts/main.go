package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/logger"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/op/go-logging"
)

var (
	log                 *logging.Logger
	MAX_ITERATION_COUNT = 50
)

func init() {
	log = logger.CreateLogger("Profile Meta Counts Migrator", "debug")
}

func main() {

	err := mongodb.Run("jAccounts", updateFunc())
	if err != nil {
		log.Info("error on accouint query.", err)
	}
}
func updateFunc() func(coll *mgo.Collection) error {
	return func(coll *mgo.Collection) error {
		query := coll.Find(modelhelper.Selector{})

		totalCount, err := query.Count()
		if err != nil {
			log.Info("Err while getting count, exiting", err)
			return err
		}

		log.Info("totalCount", totalCount)

		fmt.Println(config.Skip, config.Count)
		skip := config.Skip
		// this is a starting point
		index := skip
		// this is the item count to be processed
		limit := config.Count
		// this will be the ending point
		count := index + limit

		var account models.Account

		iteration := 0
		for {
			// if we reach to the end of the all collection, exit
			if index >= totalCount {
				log.Info("All items are processed, exiting")
				break
			}

			// this is the max re-iterating count
			if iteration == MAX_ITERATION_COUNT {
				break
			}

			// if we processed all items then exit
			if index == count {
				break
			}

			iter := query.Skip(index).Limit(count - index).Iter()
			for iter.Next(&account) {
				log.Debug("Account id", account.Id)
				err := updateCounts(account.Id)
				if err != nil {
					log.Info("Err while updating account", err)
				}
				// break
				index++
				fmt.Println(index)
			}

			if err := iter.Close(); err != nil {
				log.Info("error on iter", err)
			}

			if iter.Timeout() {
				continue
			}

			log.Info("iter existed, starting over from %v  -- %v  item(s) are processsed on this iter", index+1, index-skip)
			iteration++
		}
		if iteration == MAX_ITERATION_COUNT {
			log.Debug("Max iteration count %v reached, exiting", iteration)
		}
		log.Debug("Synced %v entries on this process", index-skip)

		return nil
	}
}

func updateCounts(id bson.ObjectId) error {
	toBeUpdatedFields := modelhelper.Selector{}

	toBeUpdatedFields["counts.likes"] = getLikeCount(id)
	toBeUpdatedFields["counts.following"] = getFollowingCount(id)
	toBeUpdatedFields["counts.followers"] = getFollowerCount(id)
	toBeUpdatedFields["counts.topics"] = getTopicCount(id)
	toBeUpdatedFields["counts.statusUpdates"] = getAuthorCount(id)
	toBeUpdatedFields["counts.comments"] = getCommentCount(id)
	toBeUpdated := modelhelper.Selector{"$set": toBeUpdatedFields}
	return modelhelper.UpdateAccount(modelhelper.Selector{"_id": id}, toBeUpdated)

}
func getLikeCount(id bson.ObjectId) int {
	selector := modelhelper.Selector{
		"targetId":   id,
		"targetName": "JAccount",
		"as":         "like",
	}
	count, err := modelhelper.RelationshipCount(selector)
	if err != nil {
		log.Info("like err", err)
		count = 0
	}
	return count
}

func getFollowingCount(id bson.ObjectId) int {
	selector := modelhelper.Selector{
		"targetId":   id,
		"targetName": "JAccount",
		"sourceName": "JAccount",
		"as":         "follower",
	}
	count, err := modelhelper.RelationshipCount(selector)
	if err != nil {
		log.Info("following err", err)
		count = 0
	}
	return count
}

func getFollowerCount(id bson.ObjectId) int {
	selector := modelhelper.Selector{
		"sourceId":   id,
		"targetName": "JAccount",
		"sourceName": "JAccount",
		"as":         "follower",
	}
	count, err := modelhelper.RelationshipCount(selector)
	if err != nil {
		log.Info("follower", err)
		count = 0
	}
	return count
}

func getTopicCount(id bson.ObjectId) int {
	selector := modelhelper.Selector{
		"targetId":   id,
		"targetName": "JAccount",
		"sourceName": "JTag",
		"as":         "follower",
	}
	count, err := modelhelper.RelationshipCount(selector)
	if err != nil {
		log.Info("topic", err)
		count = 0
	}
	return count
}

func getAuthorCount(id bson.ObjectId) int {
	selector := modelhelper.Selector{
		"targetId":   id,
		"targetName": "JAccount",
		"sourceName": "JNewStatusUpdate",
		"as":         "author",
	}
	count, err := modelhelper.RelationshipCount(selector)
	if err != nil {
		log.Info("statu update count", err)
		count = 0
	}
	return count
}

func getCommentCount(id bson.ObjectId) int {
	selector := modelhelper.Selector{
		"targetId":   id,
		"targetName": "JAccount",
		"sourceName": "JNewStatusUpdate",
		"as":         "commenter",
	}
	count, err := modelhelper.RelationshipCount(selector)
	if err != nil {
		log.Info("commet count", err)
		count = 0
	}
	return count
}
