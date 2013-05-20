package main

import (
	"fmt"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"regexp"
)

type filter struct {
	block    bool
	validate func() bool
}

type Validator struct {
	filters map[string]filter
	rules   proxyconfig.Restriction
	user    UserInfo
}

func validator(rules proxyconfig.Restriction, user UserInfo) *Validator {
	validator := &Validator{
		rules:   rules,
		user:    user,
		filters: make(map[string]filter),
	}
	return validator
}

func (v *Validator) addFilter(name string, mode bool, validateFn func() bool) {
	v.filters[name] = filter{
		block:    mode,
		validate: validateFn,
	}
}

func (v *Validator) IP() *Validator {
	if !v.rules.IP.Enabled {
		return v
	}

	f := func() bool {
		if v.rules.IP.Rule == "" {
			v.rules.IP.Block = false
			return true // assume allowed for all
		}

		rule, err := regexp.Compile(v.rules.IP.Rule)
		if err != nil {
			v.rules.IP.Block = false
			return true // dont block anyone if regex compile get wrong
		}

		return rule.MatchString(v.user.IP)
	}
	v.addFilter("ip", v.rules.IP.Block, f)
	return v
}

func (v *Validator) Country() *Validator {
	if !v.rules.Country.Enabled {
		return v
	}

	f := func() bool {
		if len(v.rules.Country.Rule) == 0 {
			v.rules.Country.Block = false
			return true // assume all
		}

		for _, country := range v.rules.Country.Rule {
			if country == v.user.Country {
				return true
			}
		}

		return false
	}

	v.addFilter("domain", v.rules.Country.Block, f)
	return v
}

func (v *Validator) Check() bool {
	for name, filter := range v.filters {
		fmt.Printf("checking for filter %s\n", name)
		if filter.block && filter.validate() {
			return false //block
		} else if !filter.block && !filter.validate() {
			return false //block
		}
	}

	// user is validated because none of the rules applied to him
	return true
}
