package sl_test

import (
	"reflect"
	"testing"
	"time"

	"koding/kites/kloud/api/sl"
)

func TestDatacenter(t *testing.T) {
	c := sl.NewSoftlayerWithOptions(opts)
	f := &sl.Filter{
		Name: "sjc01",
	}
	d := time.Now()
	datacenters, err := c.DatacentersByFilter(f)
	if err != nil {
		t.Fatalf("DatacentersByFilter(%v)=%s", f, err)
	}
	reqDur := time.Now().Sub(d)
	d = time.Now()
	xdatacenters, err := c.XDatacentersByFilter(f)
	if err != nil {
		t.Fatalf("XDatacentersByFilter(%v)=%s", f, err)
	}
	xreqDur := time.Now().Sub(d)
	t.Logf("[TEST] filtering took: client-side=%s, server-side=%s", reqDur, xreqDur)
	if !reflect.DeepEqual(datacenters, xdatacenters) {
		t.Fatalf("%+v != %+v", datacenters, xdatacenters)
	}
}
