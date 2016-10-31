package object

import (
	"fmt"
	"reflect"
)

type value struct {
	reflect.Value
	set func(reflect.Value)
}

func (v value) setString(s string) error {
	if v.set != nil {
		v.set(reflect.ValueOf(s))
	} else {
		if !v.CanSet() {
			return &SetError{
				Value: v.Value,
			}
		}

		v.SetString(s)
	}

	return nil
}

// SetError is returned by ReplaceFunc when
// it's unable to replace a string field.
type SetError struct {
	Value reflect.Value
}

// Error implements the builtin error interface.
func (se *SetError) Error() string {
	return fmt.Sprintf("value is not settable: %s", se.Value)
}

// ReplaceFunc calls fn on any string value found in v and if
// fn returns non-empty string - it tries to overwrite the
// value with it.
//
// If it fails to set new value (e.g. the field is not settable),
// it returns *SetError error.
//
// All unexported fields in v are ignored.
func ReplaceFunc(v interface{}, fn func(string) string) error {
	vv := value{Value: reflect.ValueOf(v)}
	stack := []value{vv}

	for len(stack) != 0 {
		vv, stack = stack[0], stack[1:]

		switch iv := indirect(vv.Value); iv.Kind() {
		case reflect.Map:
			for _, key := range iv.MapKeys() {
				key := key
				stack = append(stack, value{
					Value: iv.MapIndex(key),
					set: func(v reflect.Value) {
						iv.SetMapIndex(key, v)
					},
				})
			}
		case reflect.Slice:
			for i := 0; i < iv.Len(); i++ {
				i := i
				stack = append(stack, value{
					Value: iv.Index(i),
					set: func(v reflect.Value) {
						iv.Index(i).Set(v)
					},
				})
			}
		case reflect.Struct:
			for i := 0; i < iv.NumField(); i++ {
				stack = append(stack, value{
					Value: iv.Field(i),
				})
			}
		case reflect.String:
			if s := fn(iv.String()); s != "" {
				if err := vv.setString(s); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

func indirect(v reflect.Value) reflect.Value {
	for v.Kind() == reflect.Ptr || v.Kind() == reflect.Interface {
		v = v.Elem()
	}

	return v
}
