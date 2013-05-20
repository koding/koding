package main

import (
	"koding/kontrol/kontrolproxy/proxyconfig"
	"regexp"
)

type Validator struct {
	filters map[bool]func() bool
	rules   proxyconfig.Restriction
	user    UserInfo
}

func validator(rules proxyconfig.Restriction, user UserInfo) *Validator {
	validator := &Validator{
		rules:   rules,
		user:    user,
		filters: make(map[bool]func() bool),
	}
	return validator
}

func (v *Validator) addFilter(filter func() bool, mode bool) {
	v.filters[mode] = filter
}

func (v *Validator) IP() *Validator {
	if !v.rules.IP.Enabled {
		return v
	}

	f := func() bool {
		if v.rules.IP.Rule == "" { // assume allowed for all
			return false
		}

		rule, err := regexp.Compile(v.rules.IP.Rule)
		if err != nil {
			return false // dont block anyone if regex compile get wrong
		}

		return rule.MatchString(v.user.IP)
	}
	v.addFilter(f, v.rules.IP.Block)
	return v
}

func (v *Validator) Country() *Validator {
	if !v.rules.Country.Enabled {
		return v
	}

	f := func() bool {
		if len(v.rules.Country.Rule) == 0 {
			return false // dont block if country is empty
		}

		for _, country := range v.rules.Country.Rule {
			if country == v.user.Country {
				return true
			}
		}

		return false
	}

	v.addFilter(f, v.rules.Country.Block)
	return v
}

func (v *Validator) Check() bool {
	for deny, filter := range v.filters {
		if deny && filter() {
			return false //block
		} else if !deny && !filter() {
			return false //block
		}
	}

	// user is validated because none of the rules applied to him
	return true
}
