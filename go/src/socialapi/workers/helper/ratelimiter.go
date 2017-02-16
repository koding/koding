package helper

import (
	"log"

	throttled "gopkg.in/throttled/throttled.v2"
	"gopkg.in/throttled/throttled.v2/store/memstore"
)

// NewDefaultRateLimiter creates rate limiter with sane configuration for koding
func NewDefaultRateLimiter() *throttled.HTTPRateLimiter {
	memStore, err := memstore.New(65536)
	if err != nil {
		// errors only for non positive numbers, so no worries :)
		log.Fatal(err)
	}

	quota := throttled.RateQuota{
		MaxRate:  throttled.PerSec(11),
		MaxBurst: 12,
	}

	rateLimiter, err := throttled.NewGCRARateLimiter(memStore, quota)
	if err != nil {
		// we exit because this is code error and must be handled
		log.Fatalln(err)
	}

	return &throttled.HTTPRateLimiter{
		RateLimiter: rateLimiter,
		VaryBy:      &throttled.VaryBy{Cookies: []string{"clientId"}},
	}
}
