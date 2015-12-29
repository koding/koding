package sl

import (
	"reflect"
	"strings"

	"github.com/fatih/structs"
)

// ObjectMask returns object mask value, which is used in Softlayer API for
// requesting extra fields which are not being populated on request.
//
// ObjectMask assumes each field we want to read from Softlayer API has
// API name set in its json tag.
func ObjectMask(v interface{}) (mask []string) {
	for _, field := range structs.New(toStruct(v)).Fields() {
		if !field.IsExported() {
			continue
		}

		m := nameFromTag(field.Tag("json"))
		if m == "" {
			continue
		}

		child := toStruct(field.Value())
		if child == nil {
			mask = append(mask, m)
			continue
		}

		childMask := ObjectMask(child)
		if len(childMask) == 0 {
			mask = append(mask, m)
			continue
		}

		for _, child := range childMask {
			mask = append(mask, m+"."+child)
		}
	}
	return mask
}

// toStruct converts []StructType value to *StructType one in order to
// traverse over its fields with structs.New(v).Fields.
//
// If v is a nil pointer to a struct to returns a non-nil one.
func toStruct(v interface{}) interface{} {
	switch typ := reflect.TypeOf(v); typ.Kind() {
	case reflect.Ptr:
		if typ.Elem().Kind() == reflect.Struct {
			if reflect.ValueOf(v).IsNil() {
				return reflect.New(typ.Elem()).Interface()
			}
			return v
		}
	case reflect.Struct:
		return v
	case reflect.Slice:
		typ = typ.Elem()
		if typ.Kind() == reflect.Ptr {
			typ = typ.Elem()
		}
		return toStruct(reflect.New(typ).Interface())
	}
	return nil
}

// nameFromTag returns API name; it returns empty string if the name is missing
// or to be ignored (equal to "-").
func nameFromTag(s string) string {
	if i := strings.IndexRune(s, ','); i != -1 {
		s = s[:i]
	}

	if s == "-" {
		return ""
	}

	return s
}
