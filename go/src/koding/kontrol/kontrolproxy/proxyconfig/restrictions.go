package proxyconfig

import (
	"fmt"
	"koding/kontrol/kontrolproxy/models"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"time"
)

func NewRule(enabled bool, action, name string) *models.Rule {
	return &models.Rule{
		Enabled: enabled,
		Action:  action,
		Name:    name,
	}
}

func NewRestriction(domainname string) *models.Restriction {
	return &models.Restriction{
		Id:         bson.NewObjectId(),
		DomainName: domainname,
		RuleList:   make([]models.Rule, 0),
		CreatedAt:  time.Now(),
		ModifiedAt: time.Now(),
	}
}

func (p *ProxyConfiguration) AddOrUpdateRule(enabled bool, domainname, action, name string, index int, mode string) (models.Rule, error) {
	rule := models.Rule{}
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

func (p *ProxyConfiguration) GetRestrictionByDomain(domainname string) (models.Restriction, error) {
	restriction := models.Restriction{}
	err := p.Collection["restrictions"].Find(bson.M{"domainName": domainname}).One(&restriction)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}

func (p *ProxyConfiguration) GetRestrictionByID(id bson.ObjectId) (models.Restriction, error) {
	restriction := models.Restriction{}
	err := p.Collection["restrictions"].FindId(id).One(&restriction)
	if err != nil {
		return models.Restriction{}, err
	}
	return restriction, nil
}

func (p *ProxyConfiguration) GetRestrictions() []models.Restriction {
	restriction := models.Restriction{}
	restrictions := make([]models.Restriction, 0)
	iter := p.Collection["restrictions"].Find(nil).Iter()
	for iter.Next(&restriction) {
		restrictions = append(restrictions, restriction)
	}
	return restrictions
}

func deleteRule(list []models.Rule, i int) []models.Rule {
	copy(list[i:], list[i+1:])
	list[len(list)-1] = models.Rule{}
	return list[:len(list)-1]
}

func insertRule(list []models.Rule, b models.Rule, i int) []models.Rule {
	// don't allow any index for empty lists (to prevent out of range panic)
	if len(list) == 0 {
		i = 0
	}

	// don't allow index that is larger then list (to prevent out of range panic)
	if len(list) < i {
		i = len(list)
	}

	return append(list[:i], append([]models.Rule{b}, list[i:]...)...)
}
