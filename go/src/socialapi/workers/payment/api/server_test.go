package api

import (
	"socialapi/config"
	"socialapi/workers/common/tests"
	"socialapi/workers/payment"
	"testing"
)

func withTestServer(t *testing.T, f func(url string)) {
	tests.WithTestServer(t, AddHandlers, func(u string) {
		payment.Initialize(config.MustGet())
		f(u)
	})
}
