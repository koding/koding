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
