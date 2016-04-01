package modelhelper

import (
	"koding/db/models"
	"reflect"
	"sort"
	"testing"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// allCounters returns all jCounter documents; it's not usable in production,
// that's why defined only for tests.
func allCounters() ([]*models.Counter, error) {
	var counters []*models.Counter

	query := func(c *mgo.Collection) error {
		return c.Find(nil).All(&counters)
	}

	if err := Mongo.Run(CountersColl, query); err != nil {
		return nil, err
	}

	sort.Sort(models.Counters(counters))

	return counters, nil
}

func delCounters() error {
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(nil)
		return err
	}

	return Mongo.Run(CountersColl, query)
}

func TestCounter(t *testing.T) {
	initMongoConn()
	defer Close()
	defer delCounters()

	counters := []*models.Counter{{
		ID:        bson.NewObjectId(),
		Namespace: "foo",
		Type:      "member_instaces",
		Current:   10,
	}, {
		ID:        bson.NewObjectId(),
		Namespace: "foo",
		Type:      "member_stacks",
		Current:   1,
	}, {
		ID:        bson.NewObjectId(),
		Namespace: "bar",
		Type:      "member_instances",
		Current:   0,
	}, {
		ID:        bson.NewObjectId(),
		Namespace: "bar",
		Type:      "member_stacks",
		Current:   5,
	}}

	sort.Sort(models.Counters(counters))

	if err := CreateCounters(counters...); err != nil {
		t.Fatalf("CreateCounters()=%s", err)
	}

	c, err := allCounters()
	if err != nil {
		t.Fatalf("counters()=%s", err)
	}

	if !reflect.DeepEqual(counters, c) {
		t.Fatalf("got %+v, want %+v", c, counters)
	}

	decCases := []struct {
		n    int
		want int
	}{
		{7, 3},  // i=0
		{2, 0},  // i=1
		{1, 0},  // i=2
		{20, 0}, // i=3
	}

	for i, cas := range decCases {
		c := counters[i]

		err := DecrementOrCreateCounter(c.Namespace, c.Type, cas.n)
		if err != nil {
			t.Errorf("%d (%s): DecrementOrCreateCounter()=%s", i, c.ID.Hex(), err)
			continue
		}

		got, err := CounterByID(c.ID)
		if err != nil {
			t.Errorf("%d (%s): CounterByID()=%d", i, c.ID.Hex(), err)
			continue
		}

		if got.Current != cas.want {
			t.Errorf("%d (%s): got %d, want %d", i, c.ID.Hex(), got.Current, cas.want)
		}
	}
}
