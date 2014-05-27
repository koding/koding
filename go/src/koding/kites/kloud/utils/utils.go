package utils

import (
	"encoding/json"
	"fmt"
	"reflect"
)

// templateData includes our klient converts the given raw interface to a
// []byte data that can used to pass into packer.Template().
func TemplateData(raw, provisioner interface{}) ([]byte, error) {
	rawMapData, err := ToMap(raw, "mapstructure")
	if err != nil {
		return nil, err
	}

	packerTemplate := map[string]interface{}{}
	packerTemplate["builders"] = []interface{}{rawMapData}
	packerTemplate["provisioners"] = provisioner

	return json.Marshal(packerTemplate)
}

// toMap converts a struct defined by `in` to a map[string]interface{}. It only
// extract data that is defined by the given tag.
func ToMap(in interface{}, tag string) (map[string]interface{}, error) {
	out := make(map[string]interface{})

	v := reflect.ValueOf(in)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}

	// we only accept structs
	if v.Kind() != reflect.Struct {
		return nil, fmt.Errorf("only struct is allowd got %T", v)
	}

	typ := v.Type()
	for i := 0; i < v.NumField(); i++ {
		// gets us a StructField
		fi := typ.Field(i)
		if tagv := fi.Tag.Get(tag); tagv != "" {
			// set key of map to value in struct field
			out[tagv] = v.Field(i).Interface()
		}
	}
	return out, nil

}

// toUint tries to convert the given to uint type
func ToUint(x interface{}) uint {
	switch i := x.(type) {
	case float64:
		return uint(i)
	case uint:
		return i
	case int:
		return uint(i)
	case int64:
		return uint(i)
	default:
		return 0
	}
}
