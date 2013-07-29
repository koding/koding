package main

import (
	"errors"
	"fmt"
	"koding/kontrol/kontrolproxy/models"
	"regexp"
	"strconv"
	"strings"
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
	validate func() (bool, string)
}

type Validator struct {
	filters []filter
	rules   models.Restriction
	ip      string
	country string
	domain  string
}

func validator(rules models.Restriction, ip, country, domain string) *Validator {
	validator := &Validator{
		rules:   rules,
		ip:      ip,
		country: country,
		domain:  domain,
		filters: make([]filter, 0),
	}
	return validator
}

func (v *Validator) addFilter(ruletype, name, action, match string, validateFn func() (bool, string)) {
	v.filters = append(v.filters,
		filter{
			ruletype: ruletype,
			name:     name,
			action:   action,
			match:    match,
			validate: validateFn,
		})
}

func (v *Validator) CheckIP(regex string) (bool, string) {
	if regex == "all" {
		return true, "all" // assume allowed for all
	}

	re, err := regexp.Compile(regex)
	if err != nil {
		return false, "regex compile failed" // dont block anyone if regex compile get wrong
	}

	return re.MatchString(v.ip), "matched string"
}

func (v *Validator) CheckCountry(country string) (bool, string) {
	if country == "all" {
		return true, "all" // assume allowed for all
	}

	if country == v.country {
		return true, "country matched"
	}
	return false, "country did not matched"
}

func (v *Validator) CheckRequest(requestLimit, requestType string) (bool, string) {
	interval := strings.TrimPrefix(requestType, "request.")
	count, err := redisClient.Get(v.domain + ":" + interval)
	if err != nil {
		return false, "redis get failed" // if something goes wrong don't block anyone
	}

	filterCount, err := strconv.Atoi(requestLimit)
	countS, err := strconv.Atoi(string(count))

	if err != nil {
		return false, "requestLimit is not valid number" // if something goes wrong don't block anyone
	}

	if countS > filterCount {
		return true, string(count)
	}

	return false, string(count)
}

func (v *Validator) AddRules() *Validator {
	for _, rule := range v.rules.RuleList {
		if !rule.Enabled {
			continue
		}

		filter, err := proxyDB.GetFilterByField("name", rule.Name)
		if err != nil {
			continue // if not found just continue with next rule
		}

		f := func() (bool, string) {
			switch filter.Type {
			case "ip":
				return v.CheckIP(filter.Match)
			case "country":
				return v.CheckCountry(filter.Match)
			case "request.second", "request.minute", "request.hour", "request.day":
				return v.CheckRequest(filter.Match, filter.Type)
			}

			return false, "no filter matched"
		}
		v.addFilter(filter.Type, filter.Name, rule.Action, filter.Match, f)
	}

	return v
}

func (v *Validator) Check() (bool, error) {
	for _, filter := range v.filters {
		switch filter.action {
		case "deny":
			ok, data := filter.validate()
			if ok {
				reason := fmt.Sprintf("%s enanbled for filter %s. (rule: %s, got: %s)", filter.action, filter.name, filter.match, data)
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
			ok, _ := filter.validate()
			if ok {
				return true, nil
			} else {
				return false, ErrNotValidated
			}
		case "securepage":
			ok, _ := filter.validate()
			if ok {
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
