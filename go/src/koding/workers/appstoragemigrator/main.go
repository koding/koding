package main

import (
	"encoding/json"
	"flag"
	"fmt"

	"github.com/kr/pretty"

	"koding/db/models"
	helper "koding/db/mongodb/modelhelper"
	"koding/helpers"
	"koding/tools/config"
	"koding/tools/logger"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var log = logger.New("appstorage migrator")

var (
	conf           *config.Config
	flagDebug      = flag.Bool("d", false, "Debug mode")
	flagProfile    = flag.String("c", "dev", "Configuration profile from file")
	flagSkip       = flag.Int("s", 0, "Configuration profile from file")
	flagLimit      = flag.Int("l", 1000, "Configuration profile from file")
	collectionName = "jAccounts"
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
	initialize()
	log.Info("worker started")

	var resultDataType models.Account

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
	log.Info("worker finished")
}

func createFilter() helper.Selector {
	return helper.Selector{
	// "_id": bson.ObjectIdHex("53257671ce0961b05181746e"),
	}
}

func processDocuments(doc interface{}) error {
	result := *(doc.(*models.Account))
	rels, err := helper.GetAllRelationships(helper.Selector{
		"targetName": "JAppStorage",
		"sourceName": "JAccount",
		"sourceId":   result.Id,
		"as":         "appStorage",
	})
	if err != nil {
		return err
	}

	if len(rels) == 0 {
		log.Info("couldnt find any relationships")
		return nil
	}

	ids := make([]bson.ObjectId, 0)
	for _, rel := range rels {
		if rel.TargetId.Valid() {
			ids = append(ids, rel.TargetId)
		}
	}

	if len(ids) == 0 {
		log.Info("relationship ids are not valid")
		return nil
	}

	aps, err := getAppStoragesByIds(ids...)
	if err != nil {
		return err
	}

	if len(aps) == 0 {
		return nil
	}

	cas := &models.CombinedAppStorage{
		Id:        bson.NewObjectId(),
		AccountId: result.Id,
	}
	cas.Bucket = make(map[string]map[string]map[string]interface{})

	for _, ap := range aps {
		if _, ok := cas.Bucket[ap.AppID]; !ok {
			cas.Bucket[ap.AppID] = make(map[string]map[string]interface{})
		}

		if _, ok := cas.Bucket[ap.AppID]["data"]; !ok {
			cas.Bucket[ap.AppID]["data"] = make(map[string]interface{})
		}

		if len(cas.Bucket[ap.AppID]["data"]) <= len(ap.Bucket) {
			cas.Bucket[ap.AppID]["data"] = ap.Bucket
		} else {
			log.Info("skipping already set apid: %+v", ap)
		}
	}

	cass, err := getCombinedAppStorageById(result.Id)
	fmt.Printf("err %# v", pretty.Formatter(err))
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	if err == mgo.ErrNotFound {
		fmt.Println("1-->", 1)
		b, _ := json.MarshalIndent(cas, "", "	")
		fmt.Println("string(b)-->", string(b))

	} else {
		for key, data := range cas.Bucket {
			if _, ok := cass.Bucket[key]; !ok {
				cass.Bucket[key] = data
				continue
			}

			for k, datum := range data {
				if _, ok := cass.Bucket[key]["data"][k]; !ok {
					cass.Bucket[key]["data"][k] = datum
				}
			}

		}
		x, _ := json.MarshalIndent(cass, "", "	")
		fmt.Println("string(x)-->", string(x))

	}
	// fmt.Printf("cas %# v", pretty.Formatter(cas))

	// b, _ := json.MarshalIndent(cas, "", "	")
	// fmt.Println("string(b)-->", string(b))
	return nil
}

func getAppStoragesByIds(ids ...bson.ObjectId) ([]*models.AppStorage, error) {
	var appStorages []*models.AppStorage
	if err := helper.Mongo.Run("jAppStorages", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": ids}}).All(&appStorages)
	}); err != nil {
		return nil, fmt.Errorf("jappStorages lookup error: %v", err)
	}

	return appStorages, nil
}

func getCombinedAppStorageById(accountId bson.ObjectId) (*models.CombinedAppStorage, error) {
	var appStorages *models.CombinedAppStorage
	if err := helper.Mongo.Run("jCombinedAppStorages", func(c *mgo.Collection) error {
		return c.Find(bson.M{"accountId": accountId}).One(&appStorages)
	}); err != nil {
		return nil, err
	}

	return appStorages, nil
}
