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
	mode     string
	validate func() bool
}

type Validator struct {
	filters map[string]filter
	rules   proxyconfig.Restriction
	user    *UserInfo
}

func validator(rules proxyconfig.Restriction, user *UserInfo) *Validator {
	validator := &Validator{
		rules:   rules,
		user:    user,
		filters: make(map[string]filter),
	}
	return validator
}

func (v *Validator) addFilter(name, mode string, validateFn func() bool) {
	v.filters[name] = filter{
		mode:     mode,
		validate: validateFn,
	}
}

func (v *Validator) IP() *Validator {
	if !v.rules.IP.Enabled {
		return v
	}

	f := func() bool {
		if v.rules.IP.Rule == "" {
			return true // assume allowed for all
		}

		rule, err := regexp.Compile(v.rules.IP.Rule)
		if err != nil {
			return true // dont block anyone if regex compile get wrong
		}

		return rule.MatchString(v.user.IP)
	}
	v.addFilter("ip", v.rules.IP.Mode, f)
	return v
}

func (v *Validator) Country() *Validator {
	if !v.rules.Country.Enabled {
		return v
	}

	f := func() bool {
		// assume matched for an empty array
		if len(v.rules.Country.Rule) == 0 {
			return true // assume all
		}

		emptystrings := 0
		for _, country := range v.rules.Country.Rule {
			if country == "" {
				emptystrings++
			}
			if country == v.user.Country {
				return true
			}
		}

		// if the array has all empty slices assume matched
		if emptystrings == len(v.rules.Country.Rule) {
			return true //
		}

		return false
	}

	v.addFilter("domain", v.rules.Country.Mode, f)
	return v
}

func (v *Validator) Check() (bool, error) {
	for _, filter := range v.filters {
		switch filter.mode {
		case "blacklist":
			if filter.validate() {
				return false, ErrNotValidated
			}
		case "whitelist":
			if !filter.validate() {
				return false, ErrNotValidated
			}
		case "securepage":
			if filter.validate() {
				return false, ErrSecurePage
			}
		}
	}

	// user is validated because none of the rules applied to him
	fmt.Println("user is validated")
	return true, nil
}
