package main

import (
	"errors"
	"fmt"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"regexp"
)

var (
	ErrNotValidated = errors.New("not validated")
	ErrSecurePage   = errors.New("you are in secure page :)")
)

type filter struct {
	ruletype string
	name     string
	action   string
	match    string
	validate func() bool
}

type Validator struct {
	filters []filter
	rules   proxyconfig.Restriction
	user    *UserInfo
}

func validator(rules proxyconfig.Restriction, user *UserInfo) *Validator {
	validator := &Validator{
		rules:   rules,
		user:    user,
		filters: make([]filter, 0),
	}
	return validator
}

func (v *Validator) addFilter(ruletype, name, action, match string, validateFn func() bool) {
	v.filters = append(v.filters,
		filter{
			ruletype: ruletype,
			name:     name,
			action:   action,
			match:    match,
			validate: validateFn,
		})
}

func (v *Validator) AddRules() *Validator {
	for _, rule := range v.rules.RuleList {
		if !rule.Enabled {
			continue
		}

		filter, err := proxyDB.GetFilter(rule.Match)
		if err != nil {
			continue // if not found just continue with next rule
		}

		f := func() bool {
			if filter.Match == "all" {
				return true // assume allowed for all
			}

			switch filter.Type {
			case "ip":
				re, err := regexp.Compile(filter.Match)
				if err != nil {
					return false // dont block anyone if regex compile get wrong
				}

				return re.MatchString(v.user.IP)
			case "country":
				if filter.Match == v.user.Country {
					return true
				}
				return false
			}

			return false
		}

		v.addFilter(filter.Type, filter.Name, filter.Match, rule.Action, f)
	}

	return v
}

func (v *Validator) Check() (bool, error) {
	for _, filter := range v.filters {
		switch filter.action {
		case "deny":
			if filter.validate() {
				reason := fmt.Sprintf("%s (%s) for %s - %s", filter.action, filter.ruletype, filter.name, filter.match)
				go logDomainDenied(
					v.user.Domain.Domain,
					v.user.IP,
					v.user.Country,
					reason,
				)
				return false, ErrNotValidated
			} else {
				return true, nil
			}
		case "allow":
			if filter.validate() {
				return true, nil
			} else {
				return false, ErrNotValidated
			}
		case "securepage":
			if filter.validate() {
				return false, ErrSecurePage
			} else {
				return true, nil
			}
		}
	}

	// user is validated because none of the rules applied to him
	fmt.Println("user is validated")
	return true, nil
}
