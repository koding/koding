package modelhelper

import (
	"fmt"
	"koding/db/models"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewFilter(filtertype, name, match string) *models.Filter {
	return &models.Filter{
		Id:         bson.NewObjectId(),
		Type:       filtertype,
		Name:       name,
		Match:      match,
		CreatedAt:  time.Now(),
		ModifiedAt: time.Now(),
	}
}

// AddFilter adds or updates a new filter document. If "match" is
// available it updates the old document with the new arguments (except
// domainname). If not available it adds a new document with the given
// arguments.
func AddFilter(r *models.Filter) (models.Filter, error) {
	// generate name automatically if name is empty
	if r.Name == "" {
		r.Name = r.Type + "_" + r.Match
	}

	filter := *NewFilter(r.Type, r.Name, r.Match)

	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"match": r.Match}, filter)
		return err
	}

	err := Mongo.Run("jProxyFilters", query)
	if err != nil {
		fmt.Println("AddFilter error", err)
		return models.Filter{}, fmt.Errorf("filter %s exists already", r.Match)
	}

	return filter, nil
}

func DeleteFilterByField(key, value string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{key: value})
	}

	return Mongo.Run("jProxyFilters", query)
}

func GetFilterByField(key, value string) (models.Filter, error) {
	filter := models.Filter{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{key: value}).One(&filter)
	}

	err := Mongo.Run("jProxyFilters", query)
	if err != nil {
		return models.Filter{}, err
	}

	return filter, nil
}

func GetFilters() []models.Filter {
	filter := models.Filter{}
	filters := make([]models.Filter, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&filter) {
			filters = append(filters, filter)
		}
		return nil
	}

	Mongo.Run("jProxyFilters", query)
	return filters
}

func GetFilterByID(id bson.ObjectId) (models.Filter, error) {
	filter := models.Filter{}
	query := func(c *mgo.Collection) error {
		return c.FindId(id).One(&filter)
	}

	err := Mongo.Run("jProxyFilters", query)
	if err != nil {
		return models.Filter{}, err
	}
	return filter, nil
}
