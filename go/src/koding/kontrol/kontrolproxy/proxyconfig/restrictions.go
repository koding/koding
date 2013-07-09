package proxyconfig

import (
	"fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"time"
)

type Rule struct {
	// To disable or enable current rule
	Enabled bool `bson:"enabled", json:"enabled"`

	// Behaviour of the rule, deny,allow or securepage
	Action string `bson:"mode", json:"mode"`

	// Applied filter (cross-query filled)
	Name string `bson:"name", json:"name"`
}

type Restriction struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	DomainName string        `bson:"domainName" json:"domainName"`
	RuleList   []Rule        `bson:"ruleList", json:"ruleList"`
	CreatedAt  time.Time     `bson:"createdAt", json:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt", json:"modifiedAt"`
}

func NewRule(enabled bool, action, name string) *Rule {
	return &Rule{
		Enabled: enabled,
		Action:  action,
		Name:    name,
	}
}

func NewRestriction(domainname string) *Restriction {
	return &Restriction{
		Id:         bson.NewObjectId(),
		DomainName: domainname,
		RuleList:   make([]Rule, 0),
		CreatedAt:  time.Now(),
		ModifiedAt: time.Now(),
	}
}

func (p *ProxyConfiguration) AddOrUpdateRule(enabled bool, domainname, action, name string, index int, mode string) (Rule, error) {
	rule := Rule{}
	restriction, err := p.GetRestrictionByDomain(domainname)
	if err != nil {
		if err != mgo.ErrNotFound {
			return rule, err
		}
		restriction = *NewRestriction(domainname)
	}

	_, err = p.GetFilterByField("name", name)
	if err != nil {
		if err == mgo.ErrNotFound {
			return rule, fmt.Errorf("rule name '%s' does not exist. you have to create a filter that contains the name '%s'.", name, name)
		}

	}

	switch mode {
	case "add":
		for _, b := range restriction.RuleList {
			if b.Name == name {
				return rule, fmt.Errorf("rule name '%s' does exist already. not allowed.", name)
			}
		}

		rule = *NewRule(enabled, action, name)
		ruleList := insertRule(restriction.RuleList, rule, index)
		restriction.RuleList = ruleList
		restriction.ModifiedAt = time.Now()
	case "update":
		foundRule := false
		for i, b := range restriction.RuleList {
			if b.Name == name {
				foundRule = true
				rule = *NewRule(enabled, action, name)
				ruleList := deleteRule(restriction.RuleList, i)
				ruleList = insertRule(ruleList, rule, index)
				restriction.RuleList = ruleList
				restriction.ModifiedAt = time.Now()
				break
			}
		}
		if !foundRule {
			return rule, fmt.Errorf("rule name '%s' does not exist. you have to create it before you can update any rule", name)
		}
	case "default":
		return rule, fmt.Errorf("mode is not valid: '%s'.", mode)
	}

	_, err = p.Collection["restrictions"].Upsert(bson.M{"domainname": domainname}, restriction)
	if err != nil {
		return rule, err
	}

	return rule, nil
}

func (p *ProxyConfiguration) DeleteRuleByName(domainname, name string) error {
	err := p.Collection["restrictions"].Update(
		bson.M{"domainname": domainname},
		bson.M{"$pull": bson.M{"ruleList": bson.M{"name": name}}},
	)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteRestriction(domainname string) error {
	err := p.Collection["restrictions"].Remove(bson.M{"domainName": domainname})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetRestrictionByDomain(domainname string) (Restriction, error) {
	restriction := Restriction{}
	err := p.Collection["restrictions"].Find(bson.M{"domainName": domainname}).One(&restriction)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}

func (p *ProxyConfiguration) GetRestrictionByID(id bson.ObjectId) (Restriction, error) {
	restriction := Restriction{}
	err := p.Collection["restrictions"].FindId(id).One(&restriction)
	if err != nil {
		return Restriction{}, err
	}
	return restriction, nil
}

func (p *ProxyConfiguration) GetRestrictions() []Restriction {
	restriction := Restriction{}
	restrictions := make([]Restriction, 0)
	iter := p.Collection["restrictions"].Find(nil).Iter()
	for iter.Next(&restriction) {
		restrictions = append(restrictions, restriction)
	}
	return restrictions
}

func deleteRule(list []Rule, i int) []Rule {
	copy(list[i:], list[i+1:])
	list[len(list)-1] = Rule{}
	return list[:len(list)-1]
}

func insertRule(list []Rule, b Rule, i int) []Rule {
	// don't allow any index for empty lists (to prevent out of range panic)
	if len(list) == 0 {
		i = 0
	}

	// don't allow index that is larger then list (to prevent out of range panic)
	if len(list) < i {
		i = len(list)
	}

	return append(list[:i], append([]Rule{b}, list[i:]...)...)
}
