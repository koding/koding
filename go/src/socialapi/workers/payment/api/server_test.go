package api

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/tests"
	"socialapi/workers/payment"
	"testing"

	"github.com/koding/runner"
	"github.com/stripe/stripe-go"
)

// TODO(cihangir): make generalized "withTestServer"
func withTestServer(t *testing.T, f func(url string)) {
	tests.WithRunner(t, func(r *runner.Runner) {
		if r.Conf.Debug {
			stripe.LogLevel = 3
		}
		payment.Initialize(config.MustGet())
		port := tests.GetFreePort()
		mc := mux.NewConfig(r.Name, "localhost", port)
		mc.Debug = r.Conf.Debug
		m := mux.New(mc, r.Log, r.Metrics)

		AddHandlers(m)

		m.Listen()

		go r.Listen()

		f(fmt.Sprintf("http://localhost:%s", port))

		if err := r.Close(); err != nil {
			t.Fatalf("server close errored: %s", err.Error())
		}

		// shutdown server
		m.Close()
	})
}
