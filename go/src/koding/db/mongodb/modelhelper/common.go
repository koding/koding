package modelhelper

import (
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

type Selector bson.M

type Options struct {
	Limit int
	Sort  string
	Skip  int
}

var ErrNotFound = mgo.ErrNotFound

func GetObjectId(id string) bson.ObjectId {
	return bson.ObjectIdHex(id)
}

func NewObjectId() bson.ObjectId {
	return bson.NewObjectId()
}

func deleteByIdQuery(id string) func(c *mgo.Collection) error {
	selector := Selector{"_id": GetObjectId(id)}
	return func(c *mgo.Collection) error {
		return c.Remove(selector)
	}
}

func updateByIdQuery(id string, data interface{}) func(*mgo.Collection) error {
	return func(c *mgo.Collection) error {
		return c.UpdateId(GetObjectId(id), data)
	}
}

func updateQuery(s Selector, data interface{}) func(*mgo.Collection) error {
	return func(c *mgo.Collection) error {
		return c.Update(s, data)
	}
}

// TODO this is not functional
func findAllQuery(s Selector, o Options, data interface{}) func(*mgo.Collection) error {
	return func(c *mgo.Collection) error {
		q := c.Find(s)
		decorateQuery(q, o)
		return q.All(data)
	}
}

func countQuery(s Selector, o Options, count *int) func(*mgo.Collection) error {
	return func(c *mgo.Collection) error {
		q := c.Find(s)
		decorateQuery(q, o)
		result, err := q.Count()
		if err != nil {
			return err
		}
		*count = result
		return nil
	}
}

func checkExistence(id string, exists *bool) func(*mgo.Collection) error {
	s := Selector{"_id": GetObjectId(id)}
	return func(c *mgo.Collection) error {
		q := c.Find(s)
		result, err := q.Count()
		if err != nil {
			return err
		}
		*exists = result > 0
		return nil
	}
}
func insertQuery(data interface{}) func(*mgo.Collection) error {
	return func(c *mgo.Collection) error {
		return c.Insert(data)
	}
}

func decorateQuery(q *mgo.Query, o Options) {
	if o.Limit != 0 {
		q = q.Limit(o.Limit)
	}
	if o.Sort != "" {
		q = q.Sort(o.Sort)
	}
	if o.Skip != 0 {
		q = q.Skip(o.Skip)
	}
}
