package proxyconfig

import (
	"errors"
	"fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strings"
)

type Rule struct {
	// To disable or enable current rule
	Enabled bool `bson:"enabled", json:"enabled"`

	// Rule is either allowing matches or denying
	Mode string `bson:"mode", json:"mode"`

	// Matching string, like 1.1.1.1 or Turkey
	Match string `bson:"rule", json:"rule"`
}

type Restriction struct {
	Id         bson.ObjectId   `bson:"_id" json:"-"`
	DomainName string          `bson:"domainname" json:"domainname"`
	IPs        map[string]Rule `bson:"ips", json:"ips"`
	Countries  map[string]Rule `bson:"countries", json:"countries"`
}

func NewRule(enabled bool, mode, match string) *Rule {
	return &Rule{
		Enabled: enabled,
		Mode:    mode,
		Match:   match,
	}
}

func NewRestriction(domainname string) *Restriction {
	return &Restriction{
		Id:         bson.NewObjectId(),
		DomainName: domainname,
		IPs:        make(map[string]Rule),
		Countries:  make(map[string]Rule),
	}
}

func (p *ProxyConfiguration) AddRule(domainname, ruletype, match, mode string, enabled bool) error {
	restriction, err := p.GetRule(domainname)
	if err != nil {
		if err != mgo.ErrNotFound {
			return err
		}
		restriction = *NewRestriction(domainname)
	}

	if match == "" {
		return errors.New("match can't be empty")
	}

	switch ruletype {
	case "ip", "file":
		m := strings.Replace(match, ".", "_", -1) // mongo doesn't love dots for sub fields
		_, ok := restriction.IPs[m]
		if ok {
			return fmt.Errorf("ip rule for '%s' already exist", match)
		}

		rule := *NewRule(enabled, mode, match)
		restriction.IPs[m] = rule
	case "country":
		_, ok := restriction.Countries[match]
		if ok {
			return fmt.Errorf("country rule for '%s' already exist", match)
		}

		rule := *NewRule(enabled, mode, match)
		restriction.Countries[match] = rule
	}

	_, err = p.Collection["rules"].Upsert(bson.M{"domainname": domainname}, restriction)
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

func (p *ProxyConfiguration) DeleteRuleCountry(domainname, country string) error {
	err := p.Collection["rules"].Update(
		bson.M{"domainname": domainname},
		bson.M{"$unset": bson.M{"countries." + country: "1"}},
	)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteRuleIp(domainname, ip string) error {
	m := strings.Replace(ip, ".", "_", -1) // mongo doesn't love dots for sub fields
	err := p.Collection["rules"].Update(
		bson.M{"domainname": domainname},
		bson.M{"$unset": bson.M{"ips." + m: "1"}},
	)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetRule(domainname string) (Restriction, error) {
	restriction := Restriction{}
	err := p.Collection["rules"].Find(bson.M{"domainname": domainname}).One(&restriction)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}

func (p *ProxyConfiguration) GetRuleCountry(domainname, country string) (Rule, error) {
	restriction := Restriction{}
	err := p.Collection["rules"].Find(bson.M{"domainname": domainname}).Select(bson.M{"countries." + country: 1}).
		One(&restriction)
	if err != nil {
		return Rule{}, err
	}

	rule, ok := restriction.Countries[country]
	if !ok {
		return Rule{}, fmt.Errorf("country '%s' does not exist.", country)
	}
	return rule, nil
}

func (p *ProxyConfiguration) GetRuleIp(domainname, ip string) (Rule, error) {
	restriction := Restriction{}
	m := strings.Replace(ip, ".", "_", -1) // mongo doesn't love dots for sub fields
	err := p.Collection["rules"].Find(bson.M{"domainname": domainname}).Select(bson.M{"ips." + m: 1}).
		One(&restriction)
	if err != nil {
		return Rule{}, err
	}

	rule, ok := restriction.IPs[m]
	if !ok {
		return Rule{}, fmt.Errorf("ip '%s' does not exist.", ip)
	}
	return rule, nil
}

func (p *ProxyConfiguration) GetRuleIps(domainname string) ([]Rule, error) {
	restriction := Restriction{}
	err := p.Collection["rules"].Find(bson.M{"domainname": domainname}).Select(bson.M{"ips": 1}).
		One(&restriction)
	if err != nil {
		return []Rule{}, err
	}

	rules := make([]Rule, 0)
	for _, rule := range restriction.IPs {
		rules = append(rules, rule)
	}

	return rules, nil
}

func (p *ProxyConfiguration) GetRuleCountries(domainname string) ([]Rule, error) {
	restriction := Restriction{}
	err := p.Collection["rules"].Find(bson.M{"domainname": domainname}).Select(bson.M{"countries": 1}).
		One(&restriction)
	if err != nil {
		return []Rule{}, err
	}

	rules := make([]Rule, 0)
	for _, rule := range restriction.Countries {
		rules = append(rules, rule)
	}

	return rules, nil
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

func (p *ProxyConfiguration) GetRuleByID(id bson.ObjectId) (Restriction, error) {
	restriction := Restriction{}
	err := p.Collection["rules"].FindId(id).One(&restriction)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}
