package sl

import (
	"reflect"
	"strings"
)

// ObjectMask returns object mask value, which is used in Softlayer API for
// requesting extra fields which are not being populated on request.
//
// ObjectMask assumes each field we want to read from Softlayer API has
// API name set in its json tag.
func ObjectMask(v interface{}) []string {
	var objectMask []string
	typ := underlying(reflect.TypeOf(v))
	if typ.Kind() != reflect.Struct {
		panic("called ObjectMask on a non-struct value: " + typ.String())
	}

	for i := 0; i < typ.NumField(); i++ {
		field := typ.Field(i)
		if field.PkgPath != "" {
			// The field is unexported, ignore.
			continue
		}

		mask := nameFromTag(field.Tag)
		if mask == "" {
			// No name, ignore.
			continue
		}

		fieldTyp := underlying(field.Type)
		if fieldTyp.Kind() != reflect.Struct {
			objectMask = append(objectMask, mask)
			continue
		}

		childMask := ObjectMask(reflect.New(fieldTyp).Interface())
		if len(childMask) == 0 {
			objectMask = append(objectMask, mask)
			continue
		}

		for _, child := range childMask {
			objectMask = append(objectMask, mask+"."+child)
		}
	}
	return objectMask
}

func underlying(typ reflect.Type) reflect.Type {
	switch typ.Kind() {
	case reflect.Ptr, reflect.Slice:
		return underlying(typ.Elem())
	default:
		return typ
	}
}

// nameFromTag returns API name; it returns empty string if the name is missing
// or to be ignored (equal to "-").
func nameFromTag(tag reflect.StructTag) string {
	s := tag.Get("json")
	if i := strings.IndexRune(s, ','); i != -1 {
		s = s[:i]
	}

	if s == "-" {
		return ""
	}

	return s
}
