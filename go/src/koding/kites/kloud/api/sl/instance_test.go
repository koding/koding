package sl_test

import (
	"reflect"
	"testing"
	"time"

	"koding/kites/kloud/api/sl"
)

func TestInstance(t *testing.T) {
	c := sl.NewSoftlayerWithOptions(opts)
	f := &sl.Filter{}
	d := time.Now()
	instances, err := c.InstancesByFilter(f)
	if sl.IsNotFound(err) {
		t.Skip("dev environment has no instances created to test the API all")
	}
	if err != nil {
		t.Fatalf("InstancesByFilter(%v)=%s", f, err)
	}
	reqDur := time.Now().Sub(d)
	d = time.Now()
	xinstances, err := c.XInstancesByFilter(f)
	if sl.IsNotFound(err) {
		t.Skip("no instances found to perform filering / tag setting test")
	}
	if err != nil {
		t.Fatalf("XInstancesByFilter(%v)=%s", f, err)
	}
	xreqDur := time.Now().Sub(d)
	t.Logf("[TEST] filtering took: client-side=%s, server-side=%s", reqDur, xreqDur)
	if !reflect.DeepEqual(instances, xinstances) {
		t.Errorf("%+v != %+v", instances, xinstances)
	}
	id := instances[0].ID
	tags := instances[0].Tags.Copy()
	tags["test-tag"] = "test-value"
	err = c.InstanceSetTags(id, tags)
	if err != nil {
		t.Fatal(err)
	}
	f = &sl.Filter{
		ID: id,
		Tags: map[string]string{
			"tag-key": "",
		},
	}
	instances, err = c.InstancesByFilter(f)
	if err != nil {
		t.Fatal(err)
	}
	tags = instances[0].Tags.Copy()
	if v := tags["test-tag"]; v != "test-value" {
		t.Errorf(`want v="test-value"; got %q`, v)
	}
	delete(tags, "test-tag")
	if err = c.InstanceSetTags(id, tags); err != nil {
		t.Fatal(err)
	}
}
