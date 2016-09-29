package object_test

import (
	"encoding/json"
	"koding/kites/kloud/utils/object"
	"reflect"
	"testing"

	"gopkg.in/mgo.v2/bson"
)

type String struct {
	String string `json:"string" bson:"string"`
}

type Array struct {
	Array []interface{} `json:"array" bson:"array"`
}

type StringArray struct {
	String string        `json:"string" bson:"string"`
	Array  []interface{} `json:"array" bson:"array"`
}

func TestInliner(t *testing.T) {
	cases := []struct {
		first  interface{}
		second interface{}
		want   object.Object
	}{{
		&String{String: "foo"},
		&Array{Array: []interface{}{"foo", "bar"}},
		object.Object{
			"string": "foo",
			"array":  []interface{}{"foo", "bar"},
		},
	}}

	for i, cas := range cases {
		inliner := &object.Inliner{
			InlineFirst:  cas.first,
			InlineSecond: cas.second,
		}

		obj, err := inliner.Inline()
		if err != nil {
			t.Errorf("%d: Inline()=%s", i, err)
			continue
		}

		if !reflect.DeepEqual(obj, cas.want) {
			t.Errorf("%d: %# v != %# v", i, obj, cas.want)
			continue
		}

		p, err := json.Marshal(inliner)
		if err != nil {
			t.Errorf("%d: Marshal()=%s", i, err)
			continue
		}

		var obj2 object.Object
		if err := json.Unmarshal(p, &obj2); err != nil {
			t.Errorf("%d: Unmarshal()=%s", i, err)
			continue
		}

		if !reflect.DeepEqual(obj2, obj) {
			t.Errorf("%d: %# v != %# v", i, obj2, obj)
			continue
		}

		inliner2 := &object.Inliner{
			InlineFirst:  newZeroValue(cas.first),
			InlineSecond: newZeroValue(cas.second),
		}

		if err := json.Unmarshal(p, inliner2); err != nil {
			t.Errorf("%d: Unmarshal()=%s", i, err)
			continue
		}

		if !reflect.DeepEqual(inliner2, inliner) {
			t.Errorf("%d: %# v != %# v", i, inliner2, inliner)
			continue
		}

		value := &StringArray{
			String: "foo",
			Array:  []interface{}{"foo", "bar"},
		}

		obj3, err := object.ToJSON(value)
		if err != nil {
			t.Errorf("%d: ToJSON()=%s", i, err)
			continue
		}

		if !reflect.DeepEqual(obj3, obj2) {
			t.Errorf("%d: %# v != %# v", i, obj3, obj2)
			continue
		}

		p, err = bson.Marshal(inliner)
		if err != nil {
			t.Errorf("%d: Marshal()=%s", i, err)
			continue
		}

		var obj4 object.Object
		if err := bson.Unmarshal(p, &obj4); err != nil {
			t.Errorf("%d: Unmarshal()=%s", i, err)
			continue
		}

		if !reflect.DeepEqual(obj4, obj3) {
			t.Errorf("%d: %# v != %# v", i, obj4, obj3)
			continue
		}

		inliner3 := &object.Inliner{
			InlineFirst:  newZeroValue(cas.first),
			InlineSecond: newZeroValue(cas.second),
		}

		if err := bson.Unmarshal(p, &inliner3); err != nil {
			t.Errorf("%d: Unmarshal()=%s", i, err)
			continue
		}

		if !reflect.DeepEqual(inliner3, inliner2) {
			t.Errorf("%d: %# v != %# v", i, inliner3, inliner2)
			continue
		}
	}
}

func newZeroValue(v interface{}) interface{} {
	return reflect.New(reflect.TypeOf(v).Elem()).Interface()
}
