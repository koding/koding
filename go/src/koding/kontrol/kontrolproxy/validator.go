package main

import (
	"koding/kontrol/kontrolproxy/proxyconfig"
	"regexp"
)

type Validator struct {
	filters []func() bool
	rules   proxyconfig.Restriction
	user    UserInfo
}

func validator(rules proxyconfig.Restriction, user UserInfo) *Validator {
	validator := &Validator{
		rules: rules,
		user:  user,
	}
	return validator
}

func (v *Validator) addFilter(filter func() bool) {
	v.filters = append(v.filters, filter)
}

func (v *Validator) IP() *Validator {
	if !v.rules.IP.Enabled {
		return v
	}

	f := func() bool {
		if v.rules.IP.Rule == "" { // assume allowed for all
			return false
		}

		re, err := regexp.Compile(v.rules.IP.Rule)
		if err != nil {
			return false // dont block anyone if regex compile get wrong
		}

		if re.MatchString(v.user.IP) {
			return true
		}
		return false
	}
	v.addFilter(f)
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

	v.addFilter(f)
	return v
}

func (v *Validator) Check() bool {
	matchedFilters := 0
	for _, filter := range v.filters {
		if filter() {
			matchedFilters++
		}
	}

	// user is not validated because one of the rules applied to him
	if matchedFilters >= 1 {
		return false
	}

	// user is validated because none of the rules applied to him
	return true
}
