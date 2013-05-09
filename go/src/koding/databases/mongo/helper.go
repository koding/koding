package mongo

import (
	"encoding/json"
	"fmt"
	// "koding/databases/neo4j"
	"koding/tools/mapping"
	"labix.org/v2/mgo/bson"
	"strings"
	"time"
)

var (
	DATA     = make(map[string]interface{})
	ERR_DATA = make(map[string]interface{})
)

func FetchContent(id bson.ObjectId, name string) (string, error) {

	idHex := string(id.Hex())

	var jsonResult string

	collectionName := getCollectionName(name)

	collection := GetCollection(collectionName)

	result := make(map[string]interface{})
	err := collection.FindId(id).One(result)
	if err != nil {
		return "", err
	}

	fmt.Println("positive")
	// add object id and object class name
	result["id"] = idHex
	result["name"] = name
	//we need createdAt at all nodes
	if _, ok := result["meta.createdAt"]; !ok {

		if _, ok := result["createdAt"]; ok {
			result["meta.createdAt"] = result["createdAt"]
		} else if _, ok := result["modifiedAt"]; ok {
			result["meta.createdAt"] = result["modifiedAt"]
		} else if _, ok := result["meta.modifiedAt"]; ok {
			result["meta.createdAt"] = result["meta.modifiedAt"]
		} else {
			result["meta.createdAt"] = time.Now().UTC().Format("2006-01-02T15:04:05Z")
		}
	}

	jsonResult = generateJSON(result)

	return jsonResult, nil

}

//TO-DO add plural name support for names that ends with "y"
func getCollectionName(name string) string {
	//in mongo collection names are hold as "<lowercase_first_letter>...<add (s)>
	// sample if name is Koding, in database it is "kodings"

	//split name into string array
	splittedName := strings.Split(name, "")
	//uppercase first character and assign back
	splittedName[0] = strings.ToLower(splittedName[0])
	//merge string array
	name = strings.Join(splittedName, "")
	//pluralize name
	name += "s"
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
