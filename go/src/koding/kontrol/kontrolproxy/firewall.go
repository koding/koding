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

type Checker interface {
	Check() bool
}

type CheckIP struct {
	IP      string
	Pattern string
}

type CheckCountry struct {
	Country string
	Pattern string
}

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

			// country is empty for now
			checker, err := GetChecker(filter, getIP(r.RemoteAddr), "")
			if err != nil {
				continue
			}

			matched := checker.Check()
			switch rule.Action {
			case "deny":
				if matched {
					templateHandler("quotaExceeded.html", r.Host, 509).ServeHTTP(w, r)
					return
				}
			case "allow":
				if !matched {
					templateHandler("quotaExceeded.html", r.Host, 509).ServeHTTP(w, r)
					return
				}
			case "securepage":
				if !matched {
					continue
				}

				session, _ := store.Get(r, CookieVM)
				log.Debug("getting cookie for: %s", r.Host)
				cookieValue, ok := session.Values[r.Host]
				if !ok || cookieValue != MagicCookieValue {
					securePageHandler(session).ServeHTTP(w, r)
					return
				}
			}

		}

		h.ServeHTTP(w, r)
	})
}

func GetChecker(f models.Filter, ip, country string) (Checker, error) {
	switch f.Type {
	case "ip":
		return &CheckIP{IP: ip, Pattern: f.Match}, nil
	case "country":
		return &CheckCountry{Country: country, Pattern: f.Match}, nil
	}

	return nil, errors.New("no checker found")
}

func (c *CheckCountry) Check() bool {
	if c.Pattern == "all" {
		return true
	}

	if c.Pattern == c.Country {
		return true
	}

	return false
}

func (c *CheckIP) Check() bool {
	if c.Pattern == "all" {
		// assume allowed for all
		return true
	}

	matched, err := regexp.MatchString(c.Pattern, c.IP)
	if err != nil {
		// do not block if the regex fails
		return true
	}

	if matched {
		return false
	}

	return true // not matched, give access
}
