// Package main provides ...
package main

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"regexp"
)

var (
	restrictions = make(map[string]*models.Restriction)
)

func firewallHandler(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rest, err := modelhelper.GetRestrictionByDomain(r.Host)
		if err != nil {
			// don't block if we don't get a rule (pre-caution))
			h.ServeHTTP(w, r)
			return
		}

		for _, rule := range rest.RuleList {
			if !rule.Enabled {
				continue
			}

			filter, err := modelhelper.GetFilterByField("name", rule.Name)
			if err != nil {
				continue // if not found just continue with next rule
			}

			checker, err := GetChecker(filter, getIP(r.RemoteAddr))
			if err != nil {
				continue
			}

			err = checker.Check()
			switch rule.Action {
			case "deny":
				if err == nil {
					// block
				} else {
					continue
				}
			case "allow":
				if err == nil {
					//allow
					continue
				} else {
					// block
				}
			case "securepage":
				if err == nil {
					// show securepage
				} else {
					continue
				}
			}

		}

		h.ServeHTTP(w, r)
	})
}

func GetChecker(f models.Filter, ip string) (Checker, error) {
	switch f.Type {
	case "ip":
		return &CheckIP{IP: ip, Pattern: f.Match}, nil
	}

	return nil, errors.New("no checker found")
}

type Checker interface {
	Check() error
}

type CheckIP struct {
	IP      string
	Pattern string
}

func (c *CheckIP) Check() error {
	if c.Pattern == "all" {
		// assume allowed for all
		return nil
	}

	matched, err := regexp.MatchString(c.Pattern, c.IP)
	if err != nil {
		// do not block if the regex fails
		return nil
	}

	if matched {
		return errors.New("access denied")
	}

	return nil // not matched, give access
}
