package mapping

import (
	"fmt"
	"labix.org/v2/mgo/bson"
	"reflect"
	"strconv"
	"time"
)

// converts multi dimensional array into 2D
func ConvertTo2DMap(start string, data map[string]interface{}) map[string]interface{} {

	//make a map to hold local result
	result := make(map[string]interface{})

	//iterate over data map to generate a basic map[string]
	for k, v := range data {
		// k += start

		val := ""
		// values in database can be null, handle it
		if v == nil {
			// preserve null key
			result[k] = val
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
				result[k] = val
			}
		case "bson.ObjectId":
			val = v.(bson.ObjectId).Hex()
		case "int":
			//integer to ascii
			val = strconv.Itoa(v.(int))
		case "int64":
			//10-based conversion
			val = strconv.FormatInt(v.(int64), 10)
		case "uint64":
			val = strconv.FormatUint(v.(uint64), 10)
		//convert floats to 64bit-sized version as a string
		case "float64":
			// f => (-ddd.dddd, no exponent) most human readable version
			// -1 => smallest number required precision
			// 64 => 64bit based
			val = strconv.FormatFloat(v.(float64), 'f', -1, 64)
		case "bool":
			val = strconv.FormatBool(v.(bool))
		case "time.Time":
			val = v.(time.Time).UTC().Format("2006-01-02T15:04:05Z")
		case "string":
			val = v.(string)
		default:
			//there might be some others but, for now they are OK
			fmt.Println(typeOfKey)
			fmt.Println("...")
			val = ""
		}

		if val != "" {
			result[k] = val
		}

	}

	return result
}
