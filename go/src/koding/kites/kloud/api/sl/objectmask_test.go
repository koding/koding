package sl_test

import (
	"reflect"
	"testing"

	"koding/kites/kloud/api/sl"
)

type Foo struct {
	Num int `json:"num,omitempty"`
}

type Bar struct {
	Str  string `json:"str,omitempty"`
	Foos []Foo  `json:"foos,omitempty"`
}

func TestObjectMask(t *testing.T) {
	want := []string{
		"str",
		"foos.num",
	}
	mask := sl.ObjectMask(&Bar{})
	if !reflect.DeepEqual(mask, want) {
		t.Errorf("want mask=%v; got %v", want, mask)
	}
}
