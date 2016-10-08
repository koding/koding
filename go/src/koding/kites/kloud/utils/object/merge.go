package object

import "reflect"

// Merge overwrites fields in v1 with a value of complementary
// field in v2, if the field in v2 is non-empty.
func Merge(v1, v2 interface{}) {
	vv2 := reflect.ValueOf(v2).Elem()
	if !vv2.IsValid() {
		return
	}
	vv1 := reflect.ValueOf(v1).Elem()
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
