package modelhelper_test

import (
	"reflect"
	"sort"
	"testing"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

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

	if err := modelhelper.Mongo.Run(modelhelper.CountersColl, query); err != nil {
		return nil, err
	}

	sort.Sort(models.Counters(counters))

	return counters, nil
}

func delCounters() error {
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(nil)
		if err == mgo.ErrNotFound {
			return nil
		}

		return err
	}

	return modelhelper.Mongo.Run(modelhelper.CountersColl, query)
}

func TestCounter(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	if err := delCounters(); err != nil {
		t.Fatalf("delCounters()=%s", err)
	}

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
		Current:   2,
	}, {
		ID:        bson.NewObjectId(),
		Namespace: "bar",
		Type:      "member_stacks",
		Current:   5,
	}}

	sort.Sort(models.Counters(counters))

	if err := modelhelper.CreateCounters(counters...); err != nil {
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
		{7, 3}, // i=0
		{1, 0}, // i=1
		{2, 0}, // i=2
		{3, 2}, // i=3
	}

	for i, cas := range decCases {
		c := counters[i]

		err := modelhelper.DecrementOrCreateCounter(c.Namespace, c.Type, cas.n)
		if err != nil {
			t.Errorf("%d (%s): DecrementOrCreateCounter()=%s", i, c.ID.Hex(), err)
			continue
		}

		got, err := modelhelper.CounterByID(c.ID)
		if err != nil {
			t.Errorf("%d (%s): CounterByID()=%d", i, c.ID.Hex(), err)
			continue
		}

		if got.Current != cas.want {
			t.Errorf("%d (%s): got %d, want %d", i, c.ID.Hex(), got.Current, cas.want)
		}
	}

	newCases := []struct {
		namespace string
		typ       string
		n         int
	}{
		{"qux", "member_stacks", 1},    // i=0
		{"qux", "member_instances", 3}, // i=0
	}

	for i, cas := range newCases {
		err := modelhelper.DecrementOrCreateCounter(cas.namespace, cas.typ, cas.n)
		if err != nil {
			t.Errorf("%d: DecrementOrCreateCounter()=%s", i, err)
		}
	}

	c, err = modelhelper.CountersByNamespace("qux")
	if err != nil {
		t.Fatalf("CountersByNamespace()=%s", err)
	}

	if len(c) != 2 {
		t.Fatalf("got len(c)=%d, want len(c)=2", len(c))
	}
}
