// Package main provides ...
package main

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/tsenart/tb"
)

// Firewall is used per domain
type Firewall struct {
	rest      models.Restriction
	filters   map[string]models.Filter
	bucket    *tb.Bucket
	cacheTime time.Time
}

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
	Host       string
	MaxRequest int
	Interval   time.Duration
}

var (
	// cacheTimeout is used to invalidate a Firewall set for a given domain
	cacheTimeout = time.Minute

	fws   = make(map[string]*Firewall)
	fwsMu sync.Mutex
)

func NewFirewall(rest models.Restriction) *Firewall {
	f := &Firewall{
		filters:   make(map[string]models.Filter),
		rest:      rest,
		cacheTime: time.Now(),
	}

	for _, rule := range rest.RuleList {
		if !rule.Enabled {
			continue
		}

		filter, err := modelhelper.GetFilterByField("name", rule.Name)
		if err != nil {
			continue
		}

		f.filters[rule.Name] = filter
	}

	return f
}

// firewallHandler returns a http.Handler to restrict incoming requests based
// on rules and filters defined for a given domain name. It has a internal
// cache to avoid rapid lookup to mongodb.
func firewallHandler(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fwsMu.Lock()
		fw, ok := fws[r.Host]
		fwsMu.Unlock()

		// either it's not in the cache or the cache expired. In both cases go
		// and get the restriction from mongodb
		if !ok || fw.cacheTime.Add(cacheTimeout).Before(time.Now()) {
			rest, err := modelhelper.GetRestrictionByDomain(r.Host)
			if err != nil {
				// don't block if we don't get a rule (pre-caution))
				h.ServeHTTP(w, r)
				return
			}

			fw = NewFirewall(rest)
			fwsMu.Lock()
			fws[r.Host] = fw
			fwsMu.Unlock()
		}

		for _, rule := range fw.rest.RuleList {
			if a := fw.ApplyRule(rule, r); a != nil {
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
func (f *Firewall) ApplyRule(rule models.Rule, r *http.Request) http.Handler {
	if !rule.Enabled {
		return nil
	}

	filter, ok := f.filters[rule.Name]
	if !ok {
		return nil // continue with the next one
	}

	// country is empty for now
	checker, err := GetChecker(filter, getIP(r.RemoteAddr), "", r.Host)
	if err != nil {
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
	switch f.Type {
	case "ip":
		return &CheckIP{IP: ip, Pattern: f.Match}, nil
	case "country":
		return &CheckCountry{Country: country, Pattern: f.Match}, nil
	case "request.second", "request.minute":
		rate, err := strconv.Atoi(f.Match)
		if err != nil {
			return nil, err
		}

		var freq time.Duration
		switch strings.TrimPrefix(f.Type, "request.") {
		case "second":
			freq = time.Second
		case "minute":
			freq = time.Minute
		default:
			return nil, errors.New("request type malformed")
		}

		return &CheckRequest{Host: host, MaxRequest: rate, Interval: freq}, nil
	}

	return nil, fmt.Errorf("no checker found for %s", f.Type)
}

func (c *CheckRequest) Check() bool {
	fwsMu.Lock()
	fw := fws[c.Host]
	fwsMu.Unlock()

	// create a bucket only once for the first time
	if fw.bucket == nil {
		fw.bucket = tb.NewBucket(int64(c.MaxRequest), c.Interval)
		fwsMu.Lock()
		fws[c.Host] = fw
		fwsMu.Unlock()
	}

	// makes one request
	if fw.bucket.Take(1) == 0 {
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
