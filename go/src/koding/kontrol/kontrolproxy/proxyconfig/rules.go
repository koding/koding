package proxyconfig

import (
	"errors"
	"fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strings"
)

type Rule struct {
	// Type of rule, like 'ip' or 'country'
	Type string

	// Name of rule, future usage
	Name string

	// Matching string, like 1.1.1.1 or Turkey
	Match string `bson:"rule", json:"rule"`
}

type Behaviour struct {
	// To disable or enable current rule
	Enabled bool `bson:"enabled", json:"enabled"`

	// Behaviour of the rule, deny,allow or securepage
	Action string `bson:"mode", json:"mode"`

	// Rule name the behaviour is applied
	RuleName string `bson:"rulename", json:"rulename"`
}

type Restriction struct {
	Id         bson.ObjectId   `bson:"_id" json:"-"`
	DomainName string          `bson:"domainname" json:"domainname"`
	Rules      map[string]Rule `bson:"rules" json:"rules"`
	RuleList   []Behaviour     `bson:"rulelist", json:"rulelist"`
}

func NewRule(ruletype, name, match string) *Rule {
	return &Rule{
		Type:  ruletype,
		Name:  name,
		Match: match,
	}
}

func NewBehaviour(enabled bool, action, name string) *Behaviour {
	return &Behaviour{
		Enabled:  enabled,
		Action:   action,
		RuleName: name,
	}
}

func NewRestriction(domainname string) *Restriction {
	return &Restriction{
		Id:         bson.NewObjectId(),
		DomainName: domainname,
		Rules:      make(map[string]Rule),
		RuleList:   make([]Behaviour, 0),
	}
}

func (p *ProxyConfiguration) AddRule(domainname, ruletype, match string) (Rule, error) {
	restriction, err := p.GetRestriction(domainname)
	if err != nil {
		if err != mgo.ErrNotFound {
			return Rule{}, err
		}
		restriction = *NewRestriction(domainname)
	}

	if match == "" {
		return Rule{}, errors.New("match can't be empty")
	}

	m := strings.Replace(match, ".", "_", -1) // mongo doesn't love dots for sub fields
	name := ruletype + "_" + m

	_, ok := restriction.Rules[name]
	if ok {
		return Rule{}, fmt.Errorf("%s rule for '%s' already exist", ruletype, match)
	}

	rule := *NewRule(ruletype, name, match)
	restriction.Rules[name] = rule

	_, err = p.Collection["rules"].Upsert(bson.M{"domainname": domainname}, restriction)
	if err != nil {
		return Rule{}, err
	}

	return rule, nil
}

func (p *ProxyConfiguration) AddOrUpdateBehaviour(enabled bool, domainname, action, name string, index int, mode string) (Behaviour, error) {
	behaviour := Behaviour{}
	restriction, err := p.GetRestriction(domainname)
	if err != nil {
		if err != mgo.ErrNotFound {
			return behaviour, err
		}
		restriction = *NewRestriction(domainname)
	}

	_, ok := restriction.Rules[name]
	if !ok {
		return behaviour, fmt.Errorf("rule name '%s' does not exist. not allowed.", name)
	}

	switch mode {
	case "add":
		for _, b := range restriction.RuleList {
			if b.RuleName == name {
				return behaviour, fmt.Errorf("behaviour for rule name '%s' does exist already. not allowed.", name)
			}
		}

		behaviour = *NewBehaviour(enabled, action, name)
		ruleList := insertBehaviour(restriction.RuleList, behaviour, index)
		restriction.RuleList = ruleList
	case "update":
		foundBehaviour := false
		for i, b := range restriction.RuleList {
			if b.RuleName == name {
				foundBehaviour = true
				behaviour = *NewBehaviour(enabled, action, name)
				ruleList := deleteBehaviour(restriction.RuleList, i)
				ruleList = insertBehaviour(ruleList, behaviour, index)
				restriction.RuleList = ruleList
				break
			}
		}
		if !foundBehaviour {
			return behaviour, fmt.Errorf("behaviour for rule name '%s' does not exist.", name)
		}
	case "default":
		return behaviour, fmt.Errorf("mode is not valid: '%s'.", mode)
	}

	_, err = p.Collection["rules"].Upsert(bson.M{"domainname": domainname}, restriction)
	if err != nil {
		return behaviour, err
	}

	return behaviour, nil
}

func (p *ProxyConfiguration) DeleteBehaviour(domainname, rulename string) error {
	err := p.Collection["rules"].Update(
		bson.M{"domainname": domainname},
		bson.M{"$pull": bson.M{"rulelist": bson.M{"rulename": rulename}}},
	)
	if err != nil {
		return err
	}
	return nil
}
func (p *ProxyConfiguration) DeleteRestriction(domainname string) error {
	err := p.Collection["rules"].Remove(bson.M{"domainname": domainname})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteRule(domainname, rulename string) error {
	err := p.Collection["rules"].Update(
		bson.M{"domainname": domainname},
		bson.M{"$unset": bson.M{"rules." + rulename: "1"}},
	)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetRestriction(domainname string) (Restriction, error) {
	restriction := Restriction{}
	err := p.Collection["rules"].Find(bson.M{"domainname": domainname}).One(&restriction)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}

func (p *ProxyConfiguration) GetRule(domainname, rulename string) (Rule, error) {
	restriction := Restriction{}
	err := p.Collection["rules"].Find(bson.M{"domainname": domainname}).Select(bson.M{"rules." + rulename: 1}).
		One(&restriction)
	if err != nil {
		return Rule{}, err
	}

	rule, ok := restriction.Rules[rulename]
	if !ok {
		return Rule{}, fmt.Errorf("rule '%s' does not exist.", rulename)
	}
	return rule, nil
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

func deleteBehaviour(list []Behaviour, i int) []Behaviour {
	copy(list[i:], list[i+1:])
	list[len(list)-1] = Behaviour{}
	return list[:len(list)-1]
}

func insertBehaviour(list []Behaviour, b Behaviour, i int) []Behaviour {
	// don't allow any index for empty lists (to prevent out of range panic)
	if len(list) == 0 {
		i = 0
	}

	// don't allow index that is larger then list (to prevent out of range panic)
	if len(list) < i {
		i = len(list)
	}

	return append(list[:i], append([]Behaviour{b}, list[i:]...)...)
}
