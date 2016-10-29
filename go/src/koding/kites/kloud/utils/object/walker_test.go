package object_test

import (
	"errors"
	"koding/kites/kloud/utils/object"
	"reflect"
	"testing"
)

func TestWalk(t *testing.T) {
	v := map[string]interface{}{
		"key": "val",
	}

	fn := func(v object.Value) error {
		if v.Kind() != reflect.String {
			return nil
		}

		if !v.CanSet() {
			return errors.New("can't set")
		}

		v.SetString("Walk")
		v.FlushX()

		return nil
	}

	if err := object.Walk(v, fn); err != nil {
		t.Fatalf("Walk()=%s", err)
	}
}
