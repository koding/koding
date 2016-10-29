package object

import "reflect"

type Value struct {
	reflect.Value
	set func(reflect.Value)
}

func (v Value) FlushX() {
	if v.set != nil {
		v.set(v.Value)
	}
}

// Walk traverses fields of v, calling fn on leave elements.
func Walk(v interface{}, fn func(Value) error) error {
	vv := Value{Value: reflect.ValueOf(v)}
	stack := []Value{vv}

	for len(stack) != 0 {
		vv, stack = stack[0], stack[1:]

		switch iv := indirect(vv.Value); iv.Kind() {
		case reflect.Map:
			for _, key := range iv.MapKeys() {
				key := key
				stack = append(stack, Value{
					Value: iv.MapIndex(key),
					set: func(v reflect.Value) {
						iv.SetMapIndex(key, v)
					},
				})
			}
		case reflect.Slice:
			for i := 0; i < iv.Len(); i++ {
				stack = append(stack, Value{
					Value: iv.Index(i),
				})
			}
		case reflect.Struct:
			for i := 0; i < iv.NumField(); i++ {
				stack = append(stack, Value{
					Value: iv.Field(i),
				})
			}
		default:
			if err := fn(vv); err != nil {
				return err
			}
		}
	}

	return nil
}

func indirect(v reflect.Value) reflect.Value {
	for v.Kind() == reflect.Ptr {
		v = v.Elem()
	}

	return v
}
