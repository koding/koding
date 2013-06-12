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
	for _, rule := range v.rules.IPs {
		if !rule.Enabled {
			continue
		}

		f := func() bool {
			if rule.Match == "all" {
				return true // assume allowed for all
			}

			re, err := regexp.Compile(rule.Match)
			if err != nil {
				return true // dont block anyone if regex compile get wrong
			}

			return re.MatchString(v.user.IP)
		}
		v.addFilter("ip", rule.Mode, f)

	}

	return v
}

func (v *Validator) Country() *Validator {
	for _, rule := range v.rules.Countries {
		if !rule.Enabled {
			continue
		}

		f := func() bool {
			if rule.Match == "all" {
				return true // assume allowed for all
			}

			if rule.Match == v.user.Country {
				return true
			}

			return false
		}

		v.addFilter("country", rule.Mode, f)
	}

	return v
}

func (v *Validator) Check() (bool, error) {
	for _, filter := range v.filters {
		switch filter.mode {
		case "blacklist":
			if filter.validate() {
				return false, ErrNotValidated
			} else {
				return true, nil
			}
		case "whitelist":
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
