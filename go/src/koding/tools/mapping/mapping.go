package mapping

import (
	"koding/tools/logger"
	"labix.org/v2/mgo/bson"
	"reflect"
	"strconv"
	"time"
)

var log = logger.New("mapping")

// converts multi dimensional array into 2D
func ConvertTo2DMap(start string, data map[string]interface{}) map[string]interface{} {

	//make a map to hold local result
	result := make(map[string]interface{})

	//iterate over data map to generate a basic map[string]
	for k, v := range data {
		// k += start

		// values in database can be null, handle it
		if v == nil {
			// preserve null key
			result[k] = ""
			//no  need to continue
			continue
		}

		//get type of current value
		typeOfKey := reflect.TypeOf(v).String()
		//every v, will be a string at the end
		switch typeOfKey {

		//if we have an complex type, resolve it
		case "map[string]interface {}":
			//convert value to its real type
			tempVal := v.(map[string]interface{})
			//we have a lot more to-do, call recursively
			src := ConvertTo2DMap(k, tempVal)
			//get result and map while iterating
			for mapKey, mapValue := range src {
				//e.g.=>  pages.0.items.1.id : 50e61fc71964f6a837000003
				tempKey := k + "." + mapKey

				result[tempKey] = mapValue
			}
		case "int", "int64", "unit64", "float64", "bool", "string":
			result[k] = v
		// if value is an array
		case "[]interface {}":
			// casting here
			tempVal := v.([]interface{})
			//yes this is an array but, has no element in it?
			if len(tempVal) > 0 {
				for arrayKey, arrayValue := range tempVal {
					//generating a fake string map to be able to call this function
					tempMap := make(map[string]interface{})
					//add our interface into string map as own key
					tempMap[strconv.Itoa(arrayKey)] = arrayValue
					src := ConvertTo2DMap(k, tempMap)
					for arrayChildKey, arrayChildValue := range src {
						tempKeyx := k + "." + arrayChildKey
						result[tempKeyx] = arrayChildValue
					}
				}
			} else {
				// if array is nil then add key as an empty string
				result[k] = ""
			}
		case "bson.ObjectId":
			result[k] = v.(bson.ObjectId).Hex()
		case "time.Time":
			result[k] = v.(time.Time).UTC().Format("2006-01-02T15:04:05.000Z")
		default:
			//there might be some others but, for now they are OK
			log.Info(typeOfKey)
			log.Info("...")
		}
	}
	return result
}
