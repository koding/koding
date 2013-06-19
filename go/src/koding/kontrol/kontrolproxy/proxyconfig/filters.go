package proxyconfig

import (
	"fmt"
	"labix.org/v2/mgo/bson"
	"time"
)

type Filter struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Type       string        `bson:"type", json:"type"`
	Name       string        `bson:"name", json:"name" `
	Match      string        `bson:"match", json:"match"`
	CreatedAt  time.Time     `bson:"createdAt", json:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt", json:"modifiedAt"`
}

func NewFilter(filtertype, name, match string) *Filter {
	return &Filter{
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
func (p *ProxyConfiguration) AddFilter(r *Filter) (Filter, error) {
	// generate name automatically if name is empty
	if r.Name == "" {
		r.Name = r.Type + "_" + r.Match
	}

	filter := *NewFilter(r.Type, r.Name, r.Match)
	_, err := p.Collection["filters"].Upsert(bson.M{"match": r.Match}, filter)
	if err != nil {
		fmt.Println("AddFilter error", err)
		return Filter{}, fmt.Errorf("filter %s exists already", r.Match)
	}

	return filter, nil
}

func (p *ProxyConfiguration) DeleteFilterByField(key, value string) error {
	err := p.Collection["filter"].Remove(bson.M{key: value})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetFilterByField(key, value string) (Filter, error) {
	filter := Filter{}
	err := p.Collection["filters"].Find(bson.M{key: value}).One(&filter)
	if err != nil {
		return Filter{}, err
	}

	return filter, nil
}

func (p *ProxyConfiguration) GetFilters() []Filter {
	filter := Filter{}
	filters := make([]Filter, 0)
	iter := p.Collection["filters"].Find(nil).Iter()
	for iter.Next(&filter) {
		filters = append(filters, filter)
	}
	return filters
}

func (p *ProxyConfiguration) GetFilterByID(id bson.ObjectId) (Filter, error) {
	filter := Filter{}
	err := p.Collection["filters"].FindId(id).One(&filter)
	if err != nil {
		return Filter{}, err
	}
	return filter, nil
}
