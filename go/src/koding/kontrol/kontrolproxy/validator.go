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
	ip      string
	country string
	domain  string
}

func validator(rules proxyconfig.Restriction, ip, country, domain string) *Validator {
	validator := &Validator{
		rules:   rules,
		ip:      ip,
		country: country,
		domain:  domain,
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

		filter, err := proxyDB.GetFilterByField("match", rule.Match)
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

				return re.MatchString(v.ip)
			case "country":
				if filter.Match == v.country {
					return true
				}
				return false
			}

			return false
		}
		v.addFilter(filter.Type, filter.Name, rule.Action, filter.Match, f)
	}

	return v
}

func (v *Validator) Check() (bool, error) {
	for _, filter := range v.filters {
		switch filter.action {
		case "deny":
			if filter.validate() {
				reason := fmt.Sprintf("%s (%s - %s) - filter name: %s", filter.action, filter.ruletype, filter.match, filter.name)
				go domainDenied(
					v.domain,
					v.ip,
					v.country,
					reason,
				)
				return false, fmt.Errorf("%s", reason)
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

func domainDenied(domain, ip, country, reason string) {
	// log why the domain is denied with the reason itself
	if domain == "" {
		return
	}

	err := proxyDB.AddDomainDenied(domain, ip, country, reason)
	if err != nil {
		fmt.Printf("could not add domain statistisitcs for %s\n", err.Error())
	}
}
