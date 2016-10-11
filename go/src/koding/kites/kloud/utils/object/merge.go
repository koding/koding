package object

import "reflect"

// Merge overwrites fields in v1 with a value of complementary
// field in v2, if the field in v2 is non-empty.
//
// TODO(rjeczalik): Does not not merge struct fields
// recursively yet.
func Merge(v1, v2 interface{}) {
	vv1 := reflect.ValueOf(v1)
	if vv1.Kind() == reflect.Ptr {
		vv1 = vv1.Elem()
	}

	vv2 := reflect.ValueOf(v2)
	if vv2.Kind() == reflect.Ptr {
		vv2 = vv2.Elem()
	}

	if !vv2.IsValid() {
		return
	}

	if vv1.Type() != vv2.Type() {
		return
	}

	for i := 0; i < vv1.NumField(); i++ {
		field := vv2.Field(i)
		var empty bool
		switch field.Type().Kind() {
		case reflect.Chan, reflect.Func, reflect.Slice, reflect.Map:
			empty = field.IsNil()
		default:
			empty = field.Interface() == reflect.Zero(field.Type()).Interface()
		}
		if !empty {
			vv1.Field(i).Set(vv2.Field(i))
		}
	}
}
