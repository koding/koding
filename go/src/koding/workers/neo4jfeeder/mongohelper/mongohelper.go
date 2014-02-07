package mongohelper

import (
	"encoding/json"
	"errors"
	"koding/db/mongodb"
	"koding/tools/config"
	"koding/tools/logger"
	"koding/tools/mapping"
	"strings"

	"github.com/chuckpreslar/inflect"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var log = logger.New("mongohelper")
var mongo *mongodb.MongoDB

var (
	DATA     = make(map[string]interface{})
	ERR_DATA = make(map[string]interface{})
)

func MongoHelperInit(profile string) {
	conf := config.MustConfig(profile)
	mongo = mongodb.NewMongoDB(conf.Mongo)
}

func FetchOneContentBy(queryFunc func() map[string]interface{}) (map[string]interface{}, error) {
	result := queryFunc()
	if result == nil {
		return result, errors.New("no result")
	}

	result["id"] = result["_id"].(bson.ObjectId).Hex()
	result = decorateResult(result)

	return result, nil
}

func decorateResult(result map[string]interface{}) map[string]interface{} {
	id := result["_id"].(bson.ObjectId)
	result["id"] = id.Hex()

	meta := make(map[string]interface{})

	if _, ok := result["meta"]; ok {
		meta = result["meta"].(map[string]interface{})
	}

	createdAt := id.Time().UTC()
	meta["createdAt"] = createdAt.Format("2006-01-02T15:04:05.000Z")
	meta["createdAtEpoch"] = createdAt.Unix()

	result["meta"] = meta

	start := ""
	decoratedArray := mapping.ConvertTo2DMap(start, result)

	return decoratedArray
}

// TODO: DRY this with FetchContent()
func Fetch(idHex, name string) (map[string]interface{}, error) {
	id := bson.ObjectIdHex(idHex)

	result := make(map[string]interface{})

	query := func(c *mgo.Collection) error {
		return c.FindId(id).One(result)
	}

	err := mongo.Run(getCollectionName(name), query)
	if err != nil {
		return nil, err
	}

	log.Info("positive")
	result["id"] = idHex
	result["name"] = name

	meta := make(map[string]interface{})

	if _, ok := result["meta"]; ok {
		meta = result["meta"].(map[string]interface{})
	}

	createdAt := id.Time().UTC()
	meta["createdAt"] = createdAt.Format("2006-01-02T15:04:05.000Z")
	meta["createdAtEpoch"] = createdAt.Unix()

	result["meta"] = meta

	result = decorateResult(result)

	return result, nil
}

func FetchContent(id bson.ObjectId, name string) (string, error) {

	idHex := string(id.Hex())

	var jsonResult string

	result := make(map[string]interface{})
	query := func(c *mgo.Collection) error {
		return c.FindId(id).One(result)
	}

	err := mongo.Run(getCollectionName(name), query)
	if err != nil {
		return "", err
	}

	// add object id and object class name
	result["id"] = idHex
	result["name"] = name
	//we need createdAt at all nodes

	meta := make(map[string]interface{})

	if _, ok := result["meta"]; ok {
		meta = result["meta"].(map[string]interface{})
	}

	createdAt := id.Time().UTC()
	meta["createdAt"] = createdAt.Format("2006-01-02T15:04:05.000Z")
	meta["createdAtEpoch"] = createdAt.Unix()

	result["meta"] = meta

	jsonResult = generateJSON(result)
	return jsonResult, nil
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

// gets a multi dimensional array and convert it to a valid json
func generateJSON(data map[string]interface{}) string {
	start := ""
	decoratedArray := mapping.ConvertTo2DMap(start, data)
	// encode json
	res, err := json.Marshal(decoratedArray)
	if err != nil {
		log.Error("Marshalling error: %v", err)
	}
	return string(res)
}
