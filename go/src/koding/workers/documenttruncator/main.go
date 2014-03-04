// this package is for truncating the mongo
// it deletes from collections which are in ToBeDTruncatedNames
// first it deletes all related relationships from relationship collection
// then deletes from collection itself which are older than 1 month
package main

import (
	"flag"
	"koding/db/models"

	helper "koding/db/mongodb/modelhelper"
	"koding/helpers"
	"koding/tools/config"
	"koding/tools/logger"
	"time"
	"labix.org/v2/mgo/bson"
)

var log = logger.New("post truncator")

var (
	conf          *config.Config
	flagProfile   = flag.String("c", "vagrant", "Configuration profile from file")
	flagDirection = flag.String("direction", "targetName", "direction name ")
	flagSkip      = flag.Int("s", 0, "Configuration profile from file")
	flagLimit     = flag.Int("l", 1000, "Configuration profile from file")
	oneMonthAgo   = time.Now().Add(-time.Minute * 60 * 24 * 30).UTC()
)

func initialize() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	conf = config.MustConfig(*flagProfile)
	helper.Initialize(conf.Mongo)
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
		err := helpers.Iter(helper.Mongo, iterOptions)
		if err != nil {
			log.Fatal("Error while iter: %v", err)
		}
	}
	log.Info("Truncator worker finished")
}

// this is the iterator function
// iterates over all documents and  if the document's creation date is older
// than 1 month deletes all the related relationships and document itself
func truncateItems(collectionName string) func(doc interface{}) {
	return func(doc interface{}) {
		result := *(doc.(*map[string]interface{}))
		id, ok := result["_id"]
		if !ok {
			log.Error("result doesnt have _id %v", result)
			return
		}

		collectionId := (id.(bson.ObjectId))

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

		if err := helper.RemoveDocument(collectionName, collectionId); err != nil {
			log.Error("couldnt remove collectionId: %v from collectionName: %v Err: %v ", collectionId.Hex(), collectionName, err)
		}
	}
}

// deletes all related relationships
func deleteRel(id bson.ObjectId) {
	selector := helper.Selector{"$or": []helper.Selector{
		helper.Selector{"sourceId": id},
		helper.Selector{"targetId": id},
	}}

	rels, err := helper.GetAllRelationships(selector)
	if err != nil {
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
		if err := helper.DeleteRelationship(rel.Id); err != nil {
			log.Error("couldnt remove collectionId: %v from relationships Err: %v ", rel.Id.Hex(), err)
		}
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
