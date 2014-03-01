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

	"labix.org/v2/mgo/bson"
)

var log = logger.New("Guest cleaner worker")

var (
	configProfile = flag.String("c", "", "Configuration profile from file")
	flagSkip      = flag.Int("s", 0, "Configuration profile from file")
	flagLimit     = flag.Int("l", 1000, "Configuration profile from file")
	mongo         *mongodb.MongoDB
)

func initialize() {
	flag.Parse()
	if *configProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	conf := config.MustConfig(*configProfile)
	helper.Initialize(conf.Mongo)
	mongo = helper.Mongo

	log.SetLevel(logger.DEBUG)
}

func main() {
	// init the package
	initialize()

	log.Info("Guest cleaner worker started")

	iterOptions := helpers.NewIterOptions()
	iterOptions.CollectionName = "jAccounts"
	iterOptions.F = deleteGuestAccounts
	iterOptions.Filter = createFilter()
	iterOptions.DataType = &models.Account{}
	iterOptions.Log = log

	err := helpers.Iter(mongo, iterOptions)
	if err != nil {
		log.Fatal("Error while iter: %v", err)
	}
	log.Info("Guest cleaner worker finished")
}

func createFilter() helper.Selector {
	oneHourAgo := time.Now().Add(-time.Millisecond * 60).UTC()
	return helper.Selector{
		"type":           "unregistered",
		"status":         helper.Selector{"$ne": "tobedeleted"},
		"meta.createdAt": helper.Selector{"$lte": oneHourAgo},
	}
}

func deleteGuestAccounts(account interface{}) {
	acc := account.(*models.Account)
	log.Info("Deleting account: %v", acc.Profile.Nickname)
	selector := helper.Selector{"$or": []helper.Selector{
		helper.Selector{"sourceId": acc.Id},
		helper.Selector{"targetId": acc.Id},
	}}

	// Get all relationships for current acc
	rels, err := helper.GetAllRelationships(selector)
	if err != nil {
		log.Error("Error while getting the all relationships for deletion %v", err)
		return
	}

	// clear all sessions for acc
	clearAllSessions(acc)

	// clear all JNames for current acc
	clearAllNames(acc)

	// Delete documents with all their relationships
	deleteDocumentsWithRelationships(rels)

	// now time to delete acc itself
	if err := helper.RemoveAccount(acc.Id); err != nil {
		log.Error("Error while deleting the acc %v", err)
		return
	}
}

// clearAllSessions deletes related JSesssions from database
func clearAllSessions(account *models.Account) {
	selector := helper.Selector{"username": account.Profile.Nickname}
	if err := helper.RemoveAllDocuments("jSessions", selector); err != nil {
		log.Error("Error while deleting from JSession %v", err)
	}
}

// clearAllNames deletes related documents from JName collection
func clearAllNames(account *models.Account) {
	selector := helper.Selector{"name": account.Profile.Nickname}
	if err := helper.RemoveAllDocuments("jName", selector); err != nil {
		log.Error("Error while deleting from JName %v", err)
	}
}

// deleteDocumentsWithRelationships accepts a slice of Relationship
// and range over it, for each relationship checks if source or the target
// is eligible for deletion, at the end deletes the relationship itself
func deleteDocumentsWithRelationships(rels []models.Relationship) {
	if len(rels) == 0 {
		log.Info("no item to process")
		return
	}
	for _, rel := range rels {
		if checkIfEligibleToDelete(rel.SourceName) {
			deleteDocument(helper.GetCollectionName(rel.SourceName), rel.SourceId)
		}
		if checkIfEligibleToDelete(rel.TargetName) {
			deleteDocument(helper.GetCollectionName(rel.TargetName), rel.TargetId)
		}
		deleteDocument("relationships", rel.Id)
	}
}

// safe to delete those documents
var whiteListedModels = []string{"JSession", "JUser", "JVM", "JDomain", "JAppStorage", "JName"}

//checkIfEligibleToDelete ranges over whiteListedModels and returns bool as checking
// name is in that list or not
func checkIfEligibleToDelete(modelName string) bool {
	for _, name := range whiteListedModels {
		if name == modelName {
			return true
		}
	}

	log.Debug("not eligible %v", modelName)
	return false
}

// deleteDocument deletes the given id from given collection
func deleteDocument(collectionName string, id bson.ObjectId) {
	log.Debug("removing id: %v from collectionName: %v ", id.Hex(), collectionName)
	if err := helper.RemoveDocument(collectionName, id); err != nil {
		log.Error(
			"couldnt remove collectionId: %v from collectionName: %v  Error: %v",
			id.Hex(),
			collectionName,
			err,
		)
	}
}
