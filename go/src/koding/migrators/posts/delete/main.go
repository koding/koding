package main

import (
	"flag"
	mm "koding/db/mongodb"
	helper "koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/logger"
	"strings"
	"time"

	oldNeo "koding/databases/neo4j"
	"github.com/chuckpreslar/inflect"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var log = logger.New("post deleter")

type strToInf map[string]interface{}

var (
	MAX_ITERATION_COUNT = 50
	conf                *config.Config
	GUEST_GROUP_ID      = "51f41f195f07655e560001c1"
	SLEEPING_TIME       = 10 * time.Millisecond
	flagProfile         = flag.String("c", "vagrant", "Configuration profile from file")
	flagDirection       = flag.String("direction", "targetName", "direction name ")
	flagSkip            = flag.Int("s", 0, "Configuration profile from file")
	flagLimit           = flag.Int("l", 1000, "Configuration profile from file")
	mongodb             *mm.MongoDB
)

func main() {
	log.SetLevel(logger.INFO)
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	conf = config.MustConfig(*flagProfile)
	helper.Initialize(conf.Mongo)
	log.Info("Sync worker started")
	mongodb = helper.Mongo
	err := mongodb.Run("relationships", createQuery(*flagDirection))
	if err != nil {
		log.Fatal("Connecting to Mongo: %v", err)
	}
}

func createQuery(directionName string) func(coll *mgo.Collection) error {

	return func(coll *mgo.Collection) error {
		filter := strToInf{
			directionName: strToInf{"$in": ToBeDeletedNames},
			// "sourceName": strToInf{"$in": ToBeDeletedNames},
		}
		query := coll.Find(filter)

		totalCount, err := query.Count()
		if err != nil {
			log.Error("While getting count, exiting: %v", err)
			return err
		}

		skip := *flagSkip
		// this is a starting point
		index := skip
		// this is the item count to be processed
		limit := *flagLimit
		// this will be the ending point
		count := index + limit

		var result oldNeo.Relationship

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

				deleteRel(&result, directionName)

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
		log.Info("Synced %v entries on this process", index-skip)

		return nil
	}
}

func deleteRel(result *oldNeo.Relationship, directionName string) {

	var collectionName string
	var collectionId bson.ObjectId

	if directionName == "sourceName" {
		if result.SourceName == "" {
			log.Info("source name is not valid %v", result.SourceName)
			return
		}
		collectionName = getCollectionName(result.SourceName)
		collectionId = result.SourceId

	}
	if directionName == "targetName" {
		if result.TargetName == "" {
			log.Info("target name is not valid %v", result.TargetName)
			return
		}
		collectionName = getCollectionName(result.TargetName)
		collectionId = result.TargetId
	}

	if !collectionId.Valid() {
		log.Info("collectionId name is not valid %v", collectionId)
		return
	}
	log.Info("removing collectionId: %v from collectionName: %v ", collectionId.Hex(), collectionName)

	if err := mongodb.Run(collectionName, func(coll *mgo.Collection) error {
		return coll.RemoveId(collectionId)
	}); err != nil {
		log.Error("couldnt remove collectionId: %v from collectionName: %v  ", collectionId.Hex(), collectionName)
	}

	if !result.Id.Valid() {
		log.Info("relationship id is not valid %v", collectionId)
		return
	}
	if err := mongodb.Run("relationships", func(coll *mgo.Collection) error {
		return coll.RemoveId(result.Id)
	}); err != nil {
		log.Error("couldnt remove collectionId: %v from relationships  ", result.Id.Hex())
	}

}

//TO-DO add plural name support for names that ends with "y"
func getCollectionName(name string) string {
	//in mongo collection names are hold as "<lowercase_first_letter>...<add (s)>
	// sample if name is Koding, in database it is "kodings"

	//pluralize name
	name = inflect.Pluralize(name)
	//split name into string array
	splittedName := strings.Split(name, "")
	//uppercase first character and assign back
	splittedName[0] = strings.ToLower(splittedName[0])

	//merge string array
	name = strings.Join(splittedName, "")
	return name
}

var ToBeDeletedNames = []string{
	"CStatusActivity",
	"CStatus",

	"CFolloweeBucketActivity",
	"CFolloweeBucket",

	"CFollowerBucketActivity",
	"CFollowerBucket",

	"GroupJoineeBucketActivity",
	"GroupJoineeBucket",

	"GroupJoinerBucketActivity",
	"GroupJoinerBucket",

	"CInstalleeBucketActivity",
	"CInstalleeBucket",

	"CInstallerBucketActivity",
	"CInstallerBucket",

	"CLikeeBucketActivity",
	"CLikeeBucket",

	"CLikerBucketActivity",
	"CLikerBucket",

	"CReplieeBucketActivity",
	"CReplieeBucket",

	"CReplierBucketActivity",
	"CReplierBucket",

	"CCodeSnipActivity",
	"CCodeSnip",

	"CDiscussionActivity",
	"CDiscussion",

	"CBlogPostActivity",
	"CBlogPost",

	"CNewMemberBucketActivity",
	"CNewMemberBucket",

	"CRunnableActivity",
	"CRunnable",

	"CTutorialActivity",
	"CTutorial",

	"CActivity",
	"JFeed",

	"JBlogPost",
	"JChatConversation",
	"JCodeShare",
	"JCodeSnip",
	"JConversationSlice",
	"JDiscussion",
	"JDomainStat",
	"JInvitationRequest",
	"JInvitation",
	"JLocationStates",
	"JLocation",
	"JMails",
	"JMarkdownDoc",
	"JMessage",
	"JOpinion",
	"JStatusUpdate",
	"JApp",

	"JPrivateMessage",
	"JMailNotification",
	"JEmailNotification",
	"JEmailConfirmation",
}
