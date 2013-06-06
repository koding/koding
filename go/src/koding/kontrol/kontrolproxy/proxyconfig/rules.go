package proxyconfig

import (
	"encoding/json"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"labix.org/v2/mgo/bson"
	"strings"
)

const RULE_MEMCACHE_TIMEOUT = 60 //seconds

type IP struct {
	// To disable or enable current rule
	Enabled bool `bson:"enabled", json:"enabled"`

	// Rule is either allowing matches or denying
	Mode string `bson:"mode", json:"mode"`

	// Regex string
	Rule string `bson:"rule", json:"rule"`
}

type Country struct {
	// To disable or enable current rule
	Enabled bool `bson:"enabled", json:"enabled"`

	// Rule is either allowing matches or denying
	Mode string `bson:"mode", json:"mode"`

	// A slice of country names, i.e.:["Turkey", "Germany"]
	Rule []string `bson:"rule", json:"rule"`
}

type Restriction struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	DomainName string        `bson:"domainname" json:"domainname"`
	IP         IP            `bson:"ip", json:"ip"`
	Country    Country       `bson:"country", json:"country"`
}

func NewRestriction(domainname string) *Restriction {
	return &Restriction{
		Id:         bson.NewObjectId(),
		DomainName: domainname,
		IP:         IP{},
		Country:    Country{},
	}
}

func (p *ProxyConfiguration) AddRule(domainname, rulename, rule, mode string, enabled bool) error {
	restriction := *NewRestriction(domainname)
	switch rulename {
	case "ip", "file":
		restriction.IP.Enabled = enabled
		restriction.IP.Mode = mode
		restriction.IP.Rule = strings.TrimSpace(rule)
	case "country":
		restriction.Country.Enabled = enabled
		restriction.Country.Mode = mode
		cList := make([]string, 0)
		list := strings.Split(rule, ",")
		for _, country := range list {
			cList = append(cList, strings.TrimSpace(country))
		}
		restriction.Country.Rule = cList
	}
	_, err := p.Collection["rules"].Upsert(bson.M{"domainname": domainname}, restriction)
	if err != nil {
		return err
	}

	return nil
}

func (p *ProxyConfiguration) DeleteRule(domainname string) error {
	err := p.Collection["rules"].Remove(bson.M{"domainname": domainname})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetRule(domainname string) (Restriction, error) {
	mcKey := domainname + "kontrolrule"
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		restriction := Restriction{}
		err := p.Collection["rules"].Find(bson.M{"domainname": domainname}).One(&restriction)
		if err != nil {
			return restriction, fmt.Errorf("no rule for domain %s exist.", domainname)
		}
		data, err := json.Marshal(restriction)
		if err != nil {
			fmt.Printf("could not marshall restriction: %s", err)
		}

		p.MemCache.Set(&memcache.Item{
			Key:        mcKey,
			Value:      data,
			Expiration: int32(RULE_MEMCACHE_TIMEOUT),
		})
		return restriction, nil
	}

	restriction := Restriction{}
	err = json.Unmarshal(it.Value, &restriction)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}
	return restriction, nil
}

func (p *ProxyConfiguration) GetRules() []Restriction {
	restriction := Restriction{}
	rules := make([]Restriction, 0)
	iter := p.Collection["rules"].Find(nil).Iter()
	for iter.Next(&restriction) {
		rules = append(rules, restriction)
	}
	return rules
}
