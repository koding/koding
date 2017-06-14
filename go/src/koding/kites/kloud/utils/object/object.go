package object

import (
	"encoding"
	"encoding/json"
	"fmt"
	"reflect"
	"sort"
	"strconv"
	"strings"

	"github.com/fatih/structs"
	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/mapstructure"
	"gopkg.in/mgo.v2/bson"
)

// TODO(rjeczalik): Missing support for slice of structs - object's value
// is awalys zero.

// Object represents an arbitrary object.
type Object map[string]interface{}

// Keys gives list of the object's keys.
func (o Object) Keys() []string {
	if len(o) == 0 {
		return nil
	}
	keys := make([]string, 0, len(o))
	for k := range o {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

// Builder provides functionality of converting arbitrary value to
// a flat object type.
type Builder struct {
	// Tag to read when creating a key for a field. Field is ignored when
	// a tag's vaue is "-". If a field has no such tag, its lowecased
	// name is used instead.
	Tag string

	// Sep is used for creating a key for a child field.
	Sep string

	// Prefix is used for prefixing each newly created key.
	Prefix string

	// Recursive tells when struct fields should be processed as well.
	Recursive bool

	// FlagStringers, if true, makes builder do not traverse a type
	// if it implements fmt.Stringer interface.
	FlatStringers bool

	// FieldFunc is used to format struct's field name.
	//
	// By default struct's field name is used as-is.
	FieldFunc func(string) string
}

// New creates new child builder for the given prefix.
func (b *Builder) New(prefix string) *Builder {
	newB := *b
	if b.Prefix != "" {
		newB.Prefix = b.Prefix + newB.Sep + prefix
	} else {
		newB.Prefix = prefix
	}
	return &newB
}

// Build creates flat object representation of the given value v ignoring
// fields that begins with the ignored values.
func (b *Builder) Build(v interface{}, ignored ...string) Object {
	obj := make(Object)
	b.build(v, obj, ignored...)
	return obj
}

// TODO(rjeczalik): add support for patching - accept path instead of key,
// so it's possible to partially update nested structs / maps.
func (b *Builder) Set(v interface{}, key string, value interface{}) error {
	type setter interface {
		Set(string) error
	}

	for _, field := range structs.New(toStruct(v)).Fields() {
		if !field.IsExported() {
			continue
		}

		name := field.Name()
		if b.Tag != "" {
			if s := field.Tag(b.Tag); s != "" {
				name = s
			}

			if i := strings.IndexRune(name, ','); i != -1 {
				name = name[:i]
			}
		}

		if name != key {
			continue
		}

		if value == nil {
			return field.Set(reflect.Zero(reflect.TypeOf(field.Value())).Interface())
		}

		var s string

		switch v := value.(type) {
		case string:
			s = v
		case fmt.Stringer:
			s = v.String()
		default:
			s = fmt.Sprintf("%v", v)
		}

		switch f := field.Value().(type) {
		case encoding.TextUnmarshaler:
			if err := f.UnmarshalText([]byte(s)); err != nil {
				return err
			}
		case setter:
			if err := f.Set(s); err != nil {
				return err
			}
		case int:
			n, err := strconv.Atoi(s)
			if err != nil {
				return err
			}

			if err := field.Set(n); err != nil {
				return err
			}
		case bool:
			b, err := strconv.ParseBool(s)
			if err != nil {
				return err
			}

			if err := field.Set(b); err != nil {
				return err
			}
		default:
			if err := field.Set(value); err != nil {
				return err
			}
		}

		break
	}

	return nil
}

// Decode marshals map-like obj value into v.
//
// TODO(rjeczalik): Support for recursive decoding.
func (b *Builder) Decode(in, out interface{}) error {
	switch v := in.(type) {
	case *bson.Raw:
		return v.Unmarshal(out)
	case json.RawMessage:
		return json.Unmarshal([]byte(v), out)
	case []byte:
		return json.Unmarshal(v, out)
	case bson.M:
		return decode("bson", in, out)
	default:
		return decode(b.Tag, in, out)
	}
}

func extractValue(_, _ reflect.Type, v interface{}) (interface{}, error) {
	if out, ok := v.(*terraform.OutputState); ok {
		return out.Value, nil
	}
	return v, nil
}

var _ mapstructure.DecodeHookFuncType = extractValue

func decode(tag string, in, out interface{}) error {
	cfg := &mapstructure.DecoderConfig{
		Result:     out,
		TagName:    tag,
		DecodeHook: extractValue,
	}
	dec, err := mapstructure.NewDecoder(cfg)
	if err != nil {
		return err
	}
	return dec.Decode(in)

}

func (b *Builder) build(v interface{}, obj Object, ignored ...string) {
	if v == nil {
		return
	}

	for _, prefix := range ignored {
		if b.Prefix == prefix {
			return
		}
	}

	if isMapObject(v) {
		b.buildMapObject(v, obj, ignored...)
	} else {
		b.buildStruct(v, obj, ignored...)
	}
}

func (b *Builder) buildMapObject(v interface{}, obj Object, ignored ...string) {
	m := reflect.ValueOf(v)
	if m.Type().Kind() == reflect.Ptr {
		m = m.Elem()
	}
	for _, vkey := range m.MapKeys() {
		key := vkey.String()
		if key == "" {
			continue
		}

		vv := m.MapIndex(vkey).Interface()

		if !b.Recursive {
			b.set(obj, key, vv, ignored...)
			continue
		}

		if s, ok := vv.(fmt.Stringer); ok && b.FlatStringers {
			if !isNil(s) {
				b.set(obj, key, s.String(), ignored...)
			}
			continue
		}

		child := flatten(vv)
		if child == nil {
			b.set(obj, key, vv, ignored...)
			continue
		}

		b.New(key).build(child, obj, ignored...)
	}
}

func (b *Builder) buildStruct(v interface{}, obj Object, ignored ...string) {
	for _, field := range structs.New(toStruct(v)).Fields() {
		if !field.IsExported() {
			continue
		}

		key := b.keyFromField(field)
		if key == "" {
			continue
		}

		if !b.Recursive {
			b.set(obj, key, field.Value(), ignored...)
			continue
		}

		if s, ok := field.Value().(fmt.Stringer); ok && b.FlatStringers {
			if !isNil(s) {
				b.set(obj, key, s.String(), ignored...)
			}
			continue
		}

		child := flatten(field.Value())
		if child == nil {
			b.set(obj, key, field.Value(), ignored...)
			continue
		}

		b.New(key).build(child, obj, ignored...)
	}
}

func (b *Builder) set(obj Object, key string, value interface{}, ignored ...string) {
	if b.Prefix != "" {
		key = b.Prefix + b.Sep + key
	}

	for _, prefix := range ignored {
		if key == prefix {
			return
		}
	}

	// Do not overwrite existing keys.
	if _, ok := obj[key]; !ok {
		obj[key] = value
	}
}

func (b *Builder) keyFromField(f *structs.Field) string {
	tag := f.Tag(b.Tag)

	if i := strings.IndexRune(tag, ','); i != -1 {
		tag = tag[:i]
	}

	switch tag {
	case "-":
		return ""
	case "":
		return b.fieldFunc(f.Name())
	}

	return tag
}

func (b *Builder) fieldFunc(s string) string {
	if b.FieldFunc != nil {
		return b.FieldFunc(s)
	}
	return s
}

func isMapObject(v interface{}) bool {
	typ := reflect.TypeOf(v)
	if typ.Kind() == reflect.Ptr {
		typ = typ.Elem()
	}
	if typ.Kind() != reflect.Map {
		return false
	}
	return typ.Key().Kind() == reflect.String
}

func isNil(v interface{}) bool {
	switch v := reflect.ValueOf(v); v.Type().Kind() {
	case reflect.Chan, reflect.Func, reflect.Map, reflect.Ptr, reflect.Slice:
		return v.IsNil()
	default:
		return false
	}
}

func flatten(v interface{}) interface{} {
	if v == nil {
		return nil
	}
	if isMapObject(v) {
		return v
	}
	return toStruct(v)
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
		if typ.Kind() == reflect.Struct {
			return toStruct(reflect.New(typ).Interface())
		}
	}
	return nil
}
