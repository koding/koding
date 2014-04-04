// Package main provides ...
package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"regexp"
	"strconv"
	"strings"

	"github.com/juju/ratelimit"
)

var (
	restrictions = make(map[string]*models.Restriction)
	buckets      = make(map[string]*ratelimit.Bucket)
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

type CheckRequest struct {
	Host     string
	Rate     int
	RateType string
}

func firewallHandler(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rest, err := modelhelper.GetRestrictionByDomain(r.Host)
		if err != nil {
			// don't block if we don't get a rule (pre-caution))
			fmt.Println("no restriction available")
			h.ServeHTTP(w, r)
			return
		}

		fmt.Printf("%d restrictions \n", len(rest.RuleList))
		for _, rule := range rest.RuleList {
			fmt.Printf("rule %+v\n", rule)
			if a := ApplyRule(rule, r); a != nil {
				a.ServeHTTP(w, r)
				return
			}
		}

		h.ServeHTTP(w, r)
	})
}

// ApplyRule checks the rule and returns an http.Handler to be executed. A nil
// handler means there is no http.Handler to be executed. For example if the
// user is allowed to pass,  a "nil" http.Handler is returned, however if the
// user is denied a `quotaExceeded` template handler is returned that neneeds
// to be exectued
func ApplyRule(rule models.Rule, r *http.Request) http.Handler {
	if !rule.Enabled {
		return nil
	}

	filter, err := modelhelper.GetFilterByField("name", rule.Name)
	if err != nil {
		return nil // if not found just continue with next rule
	}

	fmt.Printf("filter %+v\n", filter)

	// country is empty for now
	checker, err := GetChecker(filter, getIP(r.RemoteAddr), "", r.Host)
	if err != nil {
		fmt.Println("GetChecker", err)
		return nil
	}

	matched := checker.Check()
	switch rule.Action {
	case "deny":
		if matched {
			return templateHandler("quotaExceeded.html", r.Host, 509)
		}
	case "allow":
		if !matched {
			return templateHandler("quotaExceeded.html", r.Host, 509)
		}
	case "securepage":
		if !matched {
			return nil
		}

		session, _ := store.Get(r, CookieVM)
		log.Debug("getting cookie for: %s", r.Host)
		cookieValue, ok := session.Values[r.Host]
		if !ok || cookieValue != MagicCookieValue {
			return securePageHandler(session)
		}
	}

	return nil
}

func GetChecker(f models.Filter, ip, country, host string) (Checker, error) {
	fmt.Printf("ip %+v\n", ip)

	switch f.Type {
	case "ip":
		return &CheckIP{IP: ip, Pattern: f.Match}, nil
	case "country":
		return &CheckCountry{Country: country, Pattern: f.Match}, nil
	case "request.second", "request.minute", "request.hourequest.hour":
		rate, err := strconv.Atoi(f.Match)
		if err != nil {
			return nil, err
		}

		return &CheckRequest{Host: host, Rate: rate, RateType: strings.TrimPrefix(f.Type, "request.")}, nil
	}

	return nil, fmt.Errorf("no checker found for %s", f.Type)
}

func (c *CheckRequest) Check() bool {
	var dividor float64
	switch c.RateType {
	case "second":
		dividor = 1
	case "minute":
		dividor = 60
	case "hour":
		dividor = 3600
	}

	var b *ratelimit.Bucket
	b, ok := buckets[c.Host]
	if !ok {
		b = ratelimit.NewBucketWithRate(float64(c.Rate)/dividor, int64(c.Rate))
		buckets[c.Host] = b
	}

	available := b.TakeAvailable(1) // one request

	fmt.Printf("available %+v\n", available)
	if available == 0 {
		return false
	}

	return true
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
