package proxyconfig

import (
	"fmt"
	"koding/kontrol/kontrolproxy/models"
	"labix.org/v2/mgo/bson"
	"time"
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
func (p *ProxyConfiguration) AddFilter(r *models.Filter) (models.Filter, error) {
	// generate name automatically if name is empty
	if r.Name == "" {
		r.Name = r.Type + "_" + r.Match
	}

	filter := *NewFilter(r.Type, r.Name, r.Match)
	_, err := p.Collection["filters"].Upsert(bson.M{"match": r.Match}, filter)
	if err != nil {
		fmt.Println("AddFilter error", err)
		return models.Filter{}, fmt.Errorf("filter %s exists already", r.Match)
	}

	return filter, nil
}

func (p *ProxyConfiguration) DeleteFilterByField(key, value string) error {
	err := p.Collection["filters"].Remove(bson.M{key: value})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetFilterByField(key, value string) (models.Filter, error) {
	filter := models.Filter{}
	err := p.Collection["filters"].Find(bson.M{key: value}).One(&filter)
	if err != nil {
		return models.Filter{}, err
	}

	return filter, nil
}

func (p *ProxyConfiguration) GetFilters() []models.Filter {
	filter := models.Filter{}
	filters := make([]models.Filter, 0)
	iter := p.Collection["filters"].Find(nil).Iter()
	for iter.Next(&filter) {
		filters = append(filters, filter)
	}
	return filters
}

func (p *ProxyConfiguration) GetFilterByID(id bson.ObjectId) (models.Filter, error) {
	filter := models.Filter{}
	err := p.Collection["filters"].FindId(id).One(&filter)
	if err != nil {
		return models.Filter{}, err
	}
	return filter, nil
}
