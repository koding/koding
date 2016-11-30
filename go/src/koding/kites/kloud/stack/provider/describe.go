package provider

import (
	"bytes"
	"fmt"
	"koding/kites/kloud/stack"
	"reflect"
	"strings"
	"time"
	"unicode"
)

var describeTags = []string{"bson", "hcl", "json"}

var durationTyp = reflect.TypeOf((*time.Duration)(nil)).Elem()

// Describe creates a schema definition for the given v value.
//
// It is used in "credential.describe" kloud method, for
// building (stack.Description).Credential and
// (stack.Description).Bootstrap fields.
func Describe(v interface{}) ([]stack.Value, error) {
	if v == nil {
		return nil, nil
	}

	typ := reflect.TypeOf(v)

	if typ.Kind() == reflect.Ptr {
		typ = typ.Elem()
	}

	val := reflect.ValueOf(v)
	if val.Kind() == reflect.Ptr {
		val = val.Elem()
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

		v := stack.Value{
			Name:  f.Name,
			Label: title(f.Name),
		}

		switch fTyp.Kind() {
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64,
			reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64,
			reflect.Float32, reflect.Float64:
			v.Type = "integer"
		case reflect.Slice:
			if fTyp.Elem().Kind() == reflect.Uint8 {
				v.Type = "file"
			}
		case reflect.String:
			v.Type = "string"
		case reflect.Map:
			v.Type = "object" // TODO(rjeczalik): this may be not needed
		}

		if fTyp == durationTyp {
			v.Type = "duration"
		}

		if enumer, ok := val.Field(i).Interface().(stack.Enumer); ok {
			v.Type = "enum"
			v.Values = enumer.Enums()
		}

		if v.Type == "" {
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
		if opts[0] != "" {
			v.Label = opts[0]
		}

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

var titler = strings.NewReplacer("_", " ")

func title(s string) string {
	if s == "" {
		return ""
	}

	var buf bytes.Buffer

	runes := []rune(strings.Title(titler.Replace(s)))
	buf.WriteRune(runes[0])

	for i := 1; i < len(runes)-1; i++ {
		if !unicode.IsSpace(runes[i]) && !unicode.IsSpace(runes[i-1]) && unicode.IsUpper(runes[i]) && (unicode.IsLower(runes[i+1]) || unicode.IsLower(runes[i-1])) {
			buf.WriteRune(' ')
		}

		buf.WriteRune(runes[i])
	}

	if len(runes) != 1 {
		buf.WriteRune(runes[len(runes)-1])
	}

	return buf.String()
}
