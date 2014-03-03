package main

import (
	"flag"
	"koding/db/models"
	"koding/db/mongodb"
	helper "koding/db/mongodb/modelhelper"
	"koding/helpers"
	"koding/tools/config"
	"koding/tools/logger"
	"strings"
	"time"

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
	mongo               *mongodb.MongoDB
)

func initialize() {
	flag.Parse()
	log.SetLevel(logger.INFO)
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
	log.Info("Post Deleter worker started")

	iterOptions := helpers.NewIterOptions()
	iterOptions.CollectionName = "relationships"
	iterOptions.F = deleteRel
	iterOptions.Filter = createFilter(*flagDirection)
	iterOptions.DataType = &models.Relationship{}
	iterOptions.Limit = *flagLimit
	iterOptions.Skip = *flagSkip
	iterOptions.Log = log

	log.SetLevel(logger.DEBUG)

	err := helpers.Iter(mongo, iterOptions)
	if err != nil {
		log.Fatal("Error while iter: %v", err)
	}
	log.Info("Deleter worker finished")

}

func createFilter(directionName string) helper.Selector {
	oneMonthAgo := time.Now().Add(-time.Minute * 60 * 24 * 30).UTC()
	return helper.Selector{
		directionName: helper.Selector{"$in": ToBeDeletedNames},
		"timestamp":   helper.Selector{"$lte": oneMonthAgo},
	}

}

func deleteRel(rel interface{}) {
	result := rel.(*models.Relationship)
	var collectionName string
	var collectionId bson.ObjectId
	directionName := *flagDirection

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

	if err := mongo.Run(collectionName, func(coll *mgo.Collection) error {
		return coll.RemoveId(collectionId)
	}); err != nil {
		log.Error("couldnt remove collectionId: %v from collectionName: %v  ", collectionId.Hex(), collectionName)
	}

	if !result.Id.Valid() {
		log.Info("relationship id is not valid %v", collectionId)
		return
	}
	if err := mongo.Run("relationships", func(coll *mgo.Collection) error {
		return coll.RemoveId(result.Id)
	}); err != nil {
		log.Error("couldnt remove collectionId: %v from relationships  ", result.Id.Hex())
	}

}

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
	"JMails",
	"JMarkdownDoc",
	"JMessage",
	"JOpinion",
	"JStatusUpdate",
	"JApp",

	"JMailNotification",
	"JEmailNotification",
	"JEmailConfirmation",
}
