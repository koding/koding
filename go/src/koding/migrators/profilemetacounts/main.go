package main

import (
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/tools/logger"
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
