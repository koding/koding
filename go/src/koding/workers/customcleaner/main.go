// Package customcleaner cleans some documents from mongo with iter support if
// you want to delete some records from mongo just update the collectionName and
// createFilter function
package main

import (
	"flag"

	helper "koding/db/mongodb/modelhelper"
	"koding/helpers"
	"koding/tools/config"
	"koding/tools/logger"

	"labix.org/v2/mgo/bson"
)

var log = logger.New("custom cleaner truncator")

var (
	conf           *config.Config
	flagDebug      = flag.Bool("d", false, "Debug mode")
	flagProfile    = flag.String("c", "vagrant", "Configuration profile from file")
	flagSkip       = flag.Int("s", 0, "Configuration profile from file")
	flagLimit      = flag.Int("l", 1000, "Configuration profile from file")
	collectionName = "jNames"
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
	iterOptions.CollectionName = collectionName
	iterOptions.F = processDocuments
	iterOptions.Filter = createFilter()
	iterOptions.Result = &resultDataType
	iterOptions.Limit = *flagLimit
	iterOptions.Skip = *flagSkip
	iterOptions.Log = log

	log.SetLevel(logger.INFO)
	if *flagDebug {
		log.SetLevel(logger.DEBUG)
	}

	err := helpers.Iter(helper.Mongo, iterOptions)
	if err != nil {
		log.Fatal("Error while iter: %v", err)
	}
	log.Info("Custom Deleter worker finished")
}

func createFilter() helper.Selector {
	return helper.Selector{
		"name": helper.Selector{"$regex": bson.RegEx{"^guest-", ""}},
	}
}

func processDocuments(doc interface{}) error {
	result := *(doc.(*map[string]interface{}))
	id, ok := result["_id"]
	if !ok {
		log.Error("result doesnt have _id %v", result)
		return nil
	}

	collectionId, ok := (id.(bson.ObjectId))
	if !ok {
		log.Error("collection id is not bson.ObjectId %v", id)
		return nil
	}

	if !collectionId.Valid() {
		log.Info("result id is not valid %v", collectionId)
		return nil
	}

	log.Info("removing collectionId: %v from collectionName: %v ", collectionId.Hex(), collectionName)

	if err := helper.RemoveDocument(collectionName, collectionId); err != nil {
		log.Error("couldnt remove collectionId: %v from collectionName: %v Err: %v ", collectionId.Hex(), collectionName, err)
	}
	return nil
}

// func createFilter() helper.Selector {
// 	return helper.Selector{
// 		"status": "confirmed",
// 		"registeredAt": helper.Selector{
// 			"$gte": time.Date(2015, 11, 15, 0, 0, 0, 0, time.UTC),
// 			"$lte": time.Date(2015, 11, 19, 0, 0, 0, 0, time.UTC),
// 		},
// 	}
// }

// func processDocuments(doc interface{}) error {
// 	result := *(doc.(*map[string]interface{}))

// 	fmt.Println(result["username"])

// 	sessions, _ := modelhelper.GetSessionsByUsername(result["username"].(string))
// 	s := make([]string, 0)
// 	for _, session := range sessions {
// 		s = append(s, session.ClientIP)
// 	}

// 	fmt.Println(strings.Join(s, ","), "\n")

// 	return nil
// }
