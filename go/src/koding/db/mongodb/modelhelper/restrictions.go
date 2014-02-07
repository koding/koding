package modelhelper

import (
	"fmt"
	"koding/db/models"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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

func AddOrUpdateRule(enabled bool, domainname, action, name string, index int, mode string) (models.Rule, error) {
	rule := models.Rule{}
	restriction, err := GetRestrictionByDomain(domainname)
	if err != nil {
		if err != mgo.ErrNotFound {
			return rule, err
		}
		restriction = *NewRestriction(domainname)
	}

	_, err = GetFilterByField("name", name)
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

	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"domainname": domainname}, restriction)
		return err
	}

	err = Mongo.Run("jProxyRestrictions", query)
	return rule, err
}

func DeleteRuleByName(domainname, name string) error {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"domainname": domainname},
			bson.M{"$pull": bson.M{"ruleList": bson.M{"name": name}}})
	}

	return Mongo.Run("jProxyRestrictions", query)
}

func DeleteRestriction(domainname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"domainName": domainname})
	}

	return Mongo.Run("jProxyRestrictions", query)
}

func GetRestrictionByDomain(domainname string) (models.Restriction, error) {
	restriction := models.Restriction{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"domainName": domainname}).One(&restriction)
	}

	err := Mongo.Run("jProxyRestrictions", query)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}

func GetRestrictionByID(id bson.ObjectId) (models.Restriction, error) {
	restriction := models.Restriction{}
	query := func(c *mgo.Collection) error {
		return c.FindId(id).One(&restriction)
	}

	err := Mongo.Run("jProxyRestrictions", query)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}

func GetRestrictions() []models.Restriction {
	restriction := models.Restriction{}
	restrictions := make([]models.Restriction, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&restriction) {
			restrictions = append(restrictions, restriction)
		}
		return nil
	}

	Mongo.Run("jProxyRestrictions", query)
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
