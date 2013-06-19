package mongo

import (
	"encoding/json"
	"fmt"
	"github.com/grsmv/inflect"
	"koding/tools/mapping"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strings"
)

var (
	DATA        = make(map[string]interface{})
	ERR_DATA    = make(map[string]interface{})
	COLLECTIONS = make(map[string]*mgo.Collection)
)

func FetchContent(id bson.ObjectId, name string) (string, error) {

	idHex := string(id.Hex())

	var jsonResult string

	if _, ok := COLLECTIONS[name]; !ok {
		collectionName := getCollectionName(name)

		collection := GetCollection(collectionName)
		COLLECTIONS[name] = collection
	}

	result := make(map[string]interface{})
	err := COLLECTIONS[name].FindId(id).One(result)
	if err != nil {
		return "", err
	}

	fmt.Println("positive")
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
	splittedName[1] = strings.ToUpper(splittedName[1])

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
		fmt.Println("Marshalling error:", err)
	}
	return string(res)
}
