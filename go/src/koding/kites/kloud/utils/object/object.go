package object

import (
	"reflect"
	"strings"

	"github.com/fatih/structs"
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
}

// New creates new child builder for the given prefix.
func (b *Builder) New(prefix string) *Builder {
	newB := &Builder{
		Tag:       b.Tag,
		Sep:       b.Sep,
		Recursive: b.Recursive,
	}
	if b.Prefix != "" {
		newB.Prefix = b.Prefix + newB.Sep + prefix
	} else {
		newB.Prefix = prefix
	}
	return newB
}

// Build creates flat object representation of the given value v.
func (b *Builder) Build(v interface{}) Object {
	obj := make(Object)
	b.build(v, obj)
	return obj
}

func (b *Builder) build(v interface{}, obj Object) {
	if isMapObject(v) {
		b.buildMapObject(v, obj)
	} else {
		b.buildStruct(v, obj)
	}
}

func (b *Builder) buildMapObject(v interface{}, obj Object) {
	m := reflect.ValueOf(v)
	for _, vkey := range m.MapKeys() {
		key := vkey.String()
		if key == "" {
			continue
		}

		vv := m.MapIndex(vkey).Interface()

		if !b.Recursive {
			b.set(obj, key, vv)
			continue
		}

		child := flatten(vv)
		if child == nil {
			b.set(obj, key, vv)
			continue
		}

		b.New(key).build(child, obj)
	}
}

func (b *Builder) buildStruct(v interface{}, obj Object) {
	for _, field := range structs.New(toStruct(v)).Fields() {
		if !field.IsExported() {
			continue
		}

		key := b.keyFromField(field)
		if key == "" {
			continue
		}

		if !b.Recursive {
			b.set(obj, key, field.Value())
			continue
		}

		child := flatten(field.Value())
		if child == nil {
			b.set(obj, key, field.Value())
			continue
		}

		b.New(key).build(child, obj)
	}
}

func (b *Builder) set(obj Object, key string, value interface{}) {
	if b.Prefix != "" {
		key = b.Prefix + b.Sep + key
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
		return strings.ToLower(f.Name())
	}

	return tag
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

func flatten(v interface{}) interface{} {
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
