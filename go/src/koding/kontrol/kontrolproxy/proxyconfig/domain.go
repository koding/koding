package proxyconfig

import (
	"encoding/json"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"labix.org/v2/mgo/bson"
)

const DOMAIN_MEMCACHE_TIMEOUT = 60 //seconds

type Domain struct {
	Id          bson.ObjectId `bson:"_id" json:"-"`
	Domainname  string        `bson:"domainname" json:"domainname"`
	Mode        string        `bson:"mode" json:"mode"`
	Username    string        `bson:"username" json:"username,omitempty"`
	Servicename string        `bson:"servicename,omitempty" json:"servicename,omitempty"`
	Key         string        `bson:"key" json:"key,omitempty"`
	FullUrl     string        `bson:"fullurl" json:"fullurl,omitempty"`
}

func NewDomain(domainname, mode, username, servicename, key, fullurl string) *Domain {
	return &Domain{
		Id:          bson.NewObjectId(),
		Domainname:  domainname,
		Mode:        mode,
		Username:    username,
		Servicename: servicename,
		Key:         key,
		FullUrl:     fullurl,
	}
}

func (p *ProxyConfiguration) AddDomain(domainname, mode, username, servicename, key, fullurl string) error {
	domain := *NewDomain(domainname, mode, username, servicename, key, fullurl)
	_, err := p.Collection["domains"].Upsert(bson.M{"domainname": domainname}, domain)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteDomain(domainname string) error {
	err := p.Collection["domains"].Remove(bson.M{"domainname": domainname})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetDomain(domainname string) (Domain, error) {
	mcKey := domainname + "kontroldomain"
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		domain := Domain{}
		err := p.Collection["domains"].Find(bson.M{"domainname": domainname}).One(&domain)
		if err != nil {
			return domain, err
		}

		data, err := json.Marshal(domain)
		if err != nil {
			fmt.Printf("could not marshall worker: %s", err)
		}

		p.MemCache.Set(&memcache.Item{
			Key:        mcKey,
			Value:      data,
			Expiration: int32(DOMAIN_MEMCACHE_TIMEOUT),
		})
		return domain, nil
	}

	domain := Domain{}
	err = json.Unmarshal(it.Value, &domain)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}
	return domain, nil
}

func (p *ProxyConfiguration) GetDomains() []Domain {
	domain := Domain{}
	domains := make([]Domain, 0)
	iter := p.Collection["domains"].Find(nil).Iter()
	for iter.Next(&domain) {
		domains = append(domains, domain)
	}

	return domains
}
