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
	"sync"
	"time"

	"github.com/juju/ratelimit"
)

// Firewall is used per domain
type Firewall struct {
	rules     []models.Rule
	bucket    *ratelimit.Bucket
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

	debug = false
)

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

			fw = newFirewall(rest)
			fwsMu.Lock()
			fws[r.Host] = fw
			fwsMu.Unlock()
		}

		if debug {
			fmt.Printf("fw %+v\n", fw)
		}

		if a := fw.applyRule(r); a != nil {
			a.ServeHTTP(w, r)
			return
		}

		h.ServeHTTP(w, r)
	})
}

// newFirewall creates a new firewall struct per domain. This is cached and
// invalidated every one minute.
func newFirewall(rest models.Restriction) *Firewall {
	f := &Firewall{
		rules:     make([]models.Rule, 0),
		cacheTime: time.Now(),
	}

	for _, filterID := range rest.Filters {
		filter, err := modelhelper.GetFilterByID(filterID)
		if err != nil {
			continue
		}

		if !filter.Enabled {
			continue
		}

		for _, rule := range filter.Rules {
			f.rules = append(f.rules, rule)
		}
	}

	return f
}

// applyRule checks the rule and returns an http.Handler to be executed. A nil
// handler means there is no http.Handler to be executed. For example if the
// user is allowed to pass,  a "nil" http.Handler is returned, however if the
// user is denied a `quotaExceeded` template handler is returned that neneeds
// to be exectued
func (f *Firewall) applyRule(r *http.Request) http.Handler {
	for _, rule := range f.rules {
		if !rule.Enabled {
			continue
		}

		if debug {
			fmt.Printf("rule %+v\n", rule)
		}

		checker, err := getChecker(rule, r)
		if err != nil {
			log.Error("getChecker err: %v", err)
			continue
		}

		matched := checker.Check()
		switch rule.Action {
		case "block":
			if matched {
				return templateHandler("quotaExceeded.html", r.Host, 509)
			}
		case "allow":
			if !matched {
				return templateHandler("quotaExceeded.html", r.Host, 509)
			}
		case "securepage":
			if !matched {
				continue
			}

			session, _ := store.Get(r, CookieVM)
			log.Debug("getting cookie for: %s", r.Host)
			cookieValue, ok := session.Values[r.Host]
			if !ok || cookieValue != MagicCookieValue {
				return securePageHandler(session)
			}
		default:
			log.Error("rule.Action malformed: %+v", rule)
			continue
		}
	}

	return nil
}

func getChecker(rule models.Rule, r *http.Request) (Checker, error) {
	ip := getIP(r.RemoteAddr)
	country := getCountry(ip)
	host := r.Host

	if debug {
		fmt.Printf("ip %+v country %v host %v\n", ip, country, host)
	}

	switch rule.Type {
	case "ip":
		return &CheckIP{IP: ip, Pattern: rule.Match}, nil
	case "country":
		return &CheckCountry{Country: country, Pattern: rule.Match}, nil
	case "request.second", "request.minute":
		rate, err := strconv.Atoi(rule.Match)
		if err != nil {
			return nil, fmt.Errorf("request match malformed %v err %v", rule.Match, err)
		}

		var freq time.Duration
		switch strings.TrimPrefix(rule.Type, "request.") {
		case "second":
			freq = time.Second
		case "minute":
			freq = time.Minute
		default:
			return nil, fmt.Errorf("request type malformed: %v", rule.Type)
		}

		return &CheckRequest{Host: host, MaxRequest: rate, Interval: freq}, nil
	}

	return nil, fmt.Errorf("no checker found for %s", rule.Type)
}

func (c *CheckRequest) Check() bool {
	fwsMu.Lock()
	fw := fws[c.Host]
	fwsMu.Unlock()

	// create a bucket once for the first time
	if fw.bucket == nil {
		fw.bucket = ratelimit.NewBucketWithQuantum(
			c.Interval,          // interval
			int64(c.MaxRequest), // capacity
			int64(c.MaxRequest), // token per interval
		)

		fwsMu.Lock()
		fws[c.Host] = fw
		fwsMu.Unlock()
	}

	if debug {
		fmt.Printf("fw.bucket %+v\n", fw.bucket)
	}

	// makes one request, returns zero if bucket is empty
	if fw.bucket.TakeAvailable(1) == 0 {
		return true
	}

	return false // bucket is full, allowed to do anything
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

	if debug {
		fmt.Printf("c.IP %v c.Pattern %+v\n", c.IP, c.Pattern)
	}

	matched, err := regexp.MatchString(c.Pattern, c.IP)
	if err != nil {
		// do not block if the regex fails
		return true
	}

	if matched {
		return true
	}

	return false // not matched, give access
}
