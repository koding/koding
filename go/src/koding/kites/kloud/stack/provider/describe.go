package provider

import (
	"fmt"
	"koding/kites/kloud/stack"
	"reflect"
	"strings"
)

var describeTags = []string{"bson", "hcl", "json"}

func Describe(v interface{}) ([]stack.Value, error) {
	typ := reflect.TypeOf(v)

	if typ.Kind() == reflect.Ptr {
		typ = typ.Elem()
	}

	var desc []stack.Value

	for i := 0; i < typ.NumField(); i++ {
		f := typ.Field(i)

		if f.PkgPath != "" && !f.Anonymous {
			continue
		}

		fTyp := f.Type
		if fTyp.Kind() == reflect.Ptr {
			fTyp = fTyp.Elem()
		}

		var v stack.Value

		// TODO(rjeczalik): add support for enum types
		switch fTyp.Kind() {
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64,
			reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64,
			reflect.Float32, reflect.Float64:
			v.Type = "integer"
		case reflect.String:
			v.Type = "string"
		case reflect.Map:
			v.Type = "object" // TODO(rjeczalik): this may be not needed
		default:
			return nil, fmt.Errorf("unsupported type of %q field: %s", f.Name, f.Type)
		}

		for _, tag := range describeTags {
			s := f.Tag.Get(tag)

			if i := strings.IndexRune(s, ','); i != -1 {
				s = s[:i]
			}

			if s != "" {
				v.Name = s
				break
			}
		}

		opts := strings.Split(f.Tag.Get("kloud"), ",")
		v.Label = opts[0]

		for _, opt := range opts[1:] {
			switch opt {
			case "secret":
				v.Secret = true
			case "readOnly":
				v.ReadOnly = true
			}
		}

		desc = append(desc, v)
	}

	return desc, nil
}

func mustDescribe(v interface{}) []stack.Value {
	desc, err := Describe(v)
	if err != nil {
		panic(fmt.Errorf("unable to create description for %T: %s", v, err))
	}
	return desc
}
