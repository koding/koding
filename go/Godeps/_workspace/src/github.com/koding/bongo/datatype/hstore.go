package datatype

import (
	"encoding/json"
	"fmt"
	"reflect"

	"github.com/jinzhu/gorm"
)

// TODO when i use this as datatype it gives sql error:
// sql: converting Exec argument #8's type: unsupported type datatype.Hstore, a map
// find another way for this
type Hstore gorm.Hstore

func (h *Hstore) UnmarshalJSON(data []byte) error {
	hMap := map[string]interface{}{}
	if err := json.Unmarshal(data, &hMap); err != nil {
		return err
	}

	if len(hMap) == 0 {
		return nil
	}

	resultMap := make(map[string]*string)
	for key, value := range hMap {
		// when value is a map, then marshal it
		if reflect.ValueOf(value).Kind() == reflect.Map {
			res, err := json.Marshal(value)
			if err != nil {
				return err
			}

			s := string(res)
			resultMap[key] = &s
			continue
		}

		// for the other types convert value to string
		str := fmt.Sprintf("%v", value)
		resultMap[key] = &str
	}
	*h = resultMap

	return nil
}

func (h Hstore) MarshalJSON() ([]byte, error) {
	if len(h) == 0 {
		return json.Marshal(nil)
	}

	sqlMap := map[string]interface{}{}
	for key := range h {
		var res map[string]interface{}
		if err := json.Unmarshal([]byte(fmt.Sprintf("%v", *(h[key]))), &res); err != nil {
			sqlMap[key] = *(h[key])
		}
	}

	return json.Marshal(sqlMap)
}
