package main

import (
	"flag"
	"fmt"
	"koding/db/models"
	mm "koding/db/mongodb"
	helper "koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/logger"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var log = logger.New("post truncator")

type strToInf map[string]interface{}

var (
	MAX_ITERATION_COUNT = 50
	conf                *config.Config
	SLEEPING_TIME       = 10 * time.Millisecond
	oneMonthAgo         = time.Now().Add(-time.Hour * 24 * 30).UTC()
	flagProfile         = flag.String("c", "vagrant", "Configuration profile from file")
	flagSkip            = flag.Int("s", 0, "Configuration profile from file")
	flagLimit           = flag.Int("l", 1000, "Configuration profile from file")
	mongodb             *mm.MongoDB
	deletedItems        = 0
)

func main() {
	log.SetLevel(logger.DEBUG)
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	conf = config.MustConfig(*flagProfile)
	helper.Initialize(conf.Mongo)
	log.Info("Sync worker started")
	mongodb = helper.Mongo
	for _, coll := range ToBeDTruncatedNames {
		collName := coll
		err := mongodb.Run(collName, createQuery(collName))
		if err != nil {
			log.Fatal("Connecting to Mongo: %v", err)
		}
	}

}

func createQuery(collectionName string) func(coll *mgo.Collection) error {
	return func(coll *mgo.Collection) error {

		query := coll.Find(helper.Selector{})
		totalCount, err := query.Count()
		if err != nil {
			log.Error("While getting count, exiting: %v", err)
			return err
		}

		if totalCount == 0 {
			fmt.Println("Collection is empty ", collectionName)
			log.Info("deleted item count %v", deletedItems)
			return nil
		}

		skip := *flagSkip
		// this is a starting point
		index := skip
		// this is the item count to be processed
		limit := *flagLimit
		// this will be the ending point
		count := index + limit

		var result map[string]interface{}

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
			for iter.Next(&result) {
				time.Sleep(SLEEPING_TIME)

				deleteDoc(result, collectionName)

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

		if iteration == MAX_ITERATION_COUNT {
			log.Info("Max iteration count %v reached, exiting", iteration)
		}
		log.Info("%v entries on this process", index-skip)
		log.Info("deleted item count %v", deletedItems)

		return nil
	}
}

func deleteDoc(result map[string]interface{}, collectionName string) {

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

	if err := mongodb.Run(collectionName, func(coll *mgo.Collection) error {
		return coll.RemoveId(collectionId)
	}); err != nil {
		log.Error("couldnt remove collectionId: %v from collectionName: %v  ", collectionId.Hex(), collectionName)
	}
	deletedItems++
}

func deleteRel(id bson.ObjectId) {
	var rels []models.Relationship
	if err := mongodb.Run("relationships", func(coll *mgo.Collection) error {
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
		if err := mongodb.Run("relationships", func(coll *mgo.Collection) error {
			return coll.RemoveId(rel.Id)
		}); err != nil {
			log.Error("couldnt remove collectionId: %v from relationships  ", rel.Id.Hex())
		}
		deletedItems++
	}
}

var ToBeDTruncatedNames = []string{
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
