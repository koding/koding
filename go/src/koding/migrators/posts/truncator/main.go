// this package is for truncating the mongo
// it deletes from collections which are in ToBeDTruncatedNames
// first it deletes all related relationships from relationship collection
// then deletes from collection itself which are older than 1 month
package main

import (
	"flag"
	"koding/db/models"
	"koding/db/mongodb"

	helper "koding/db/mongodb/modelhelper"
	"koding/helpers"
	"koding/tools/config"
	"koding/tools/logger"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var log = logger.New("post truncator")

var (
	conf          *config.Config
	flagProfile   = flag.String("c", "vagrant", "Configuration profile from file")
	flagDirection = flag.String("direction", "targetName", "direction name ")
	flagSkip      = flag.Int("s", 0, "Configuration profile from file")
	flagLimit     = flag.Int("l", 1000, "Configuration profile from file")
	mongo         *mongodb.MongoDB
	deletedItems  = 0
	oneMonthAgo   = time.Now().Add(-time.Minute * 60 * 24 * 30).UTC()
)

func initialize() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	conf = config.MustConfig(*flagProfile)
	helper.Initialize(conf.Mongo)
	mongo = helper.Mongo
}

func main() {
	// init the package
	initialize()
	log.Info("Truncater worker started")

	var resultDataType map[string]interface{}

	iterOptions := helpers.NewIterOptions()
	iterOptions.Filter = helper.Selector{}
	iterOptions.DataType = &resultDataType
	iterOptions.Limit = *flagLimit
	iterOptions.Skip = *flagSkip
	iterOptions.Log = log

	log.SetLevel(logger.DEBUG)
	for _, coll := range ToBeTruncatedNames {
		iterOptions.CollectionName = coll
		iterOptions.F = truncateItems(coll)
		err := helpers.Iter(mongo, iterOptions)
		if err != nil {
			log.Fatal("Error while iter: %v", err)
		}
	}
	log.Info("Truncator worker finished")
}

// this is the iterator function
func truncateItems(collectionName string) func(doc interface{}) {
	return func(doc interface{}) {
		result := *(doc.(*map[string]interface{}))
		id, ok := result["_id"]
		if !ok {
			log.Error("result doesnt have _id %v", result)
			return
		}
		var collectionId bson.ObjectId

		collectionId = (id.(bson.ObjectId))

		if !collectionId.Valid() {
			log.Info("result id is not valid %v", collectionId)
			return
		}

		if collectionId.Time().UTC().UnixNano() > oneMonthAgo.UnixNano() {
			log.Info("not deleting docuemnt %v", collectionId.Time())
			return
		}

		deleteRel(collectionId)

		log.Info("removing collectionId: %v from collectionName: %v ", collectionId.Hex(), collectionName)

		if err := mongo.Run(collectionName, func(coll *mgo.Collection) error {
			return coll.RemoveId(collectionId)
		}); err != nil {
			log.Error("couldnt remove collectionId: %v from collectionName: %v  ", collectionId.Hex(), collectionName)
		}
		deletedItems++
	}
}

func deleteRel(id bson.ObjectId) {
	var rels []models.Relationship
	if err := mongo.Run("relationships", func(coll *mgo.Collection) error {
		selector := helper.Selector{"$or": []helper.Selector{
			helper.Selector{"sourceId": id},
			helper.Selector{"targetId": id},
		}}
		return coll.Find(selector).All(&rels)
	}); err != nil {
		log.Error("couldnt fetch collectionId: %v from relationships  ", id.Hex())
		return
	}

	deleteDocumentsFromRelationships(rels)
}

func deleteDocumentsFromRelationships(rels []models.Relationship) {
	if len(rels) == 0 {
		log.Info("document has no relationship")
		return
	}

	for _, rel := range rels {
		if err := mongo.Run("relationships", func(coll *mgo.Collection) error {
			return coll.RemoveId(rel.Id)
		}); err != nil {
			log.Error("couldnt remove collectionId: %v from relationships  ", rel.Id.Hex())
		}
		deletedItems++
	}
}

var ToBeTruncatedNames = []string{
	"cActivities",
	"cFolloweeBuckets",
	"cLikeeBuckets",
	"cLikerBuckets",
	"cNewMemberBuckets",
	"cReplieeBuckets",
	"jEmailConfirmations",
	"jEmailNotifications",
	"jInvitationRequests",
	"jInvitations",
	"jLogs",
	"jMailNotifications",
	"jMails",
	"jOldUsers",
	"jPasswordRecoveries",
	"jVerificationTokens",
}
