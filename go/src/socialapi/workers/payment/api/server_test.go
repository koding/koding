package api

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
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
	const workerName = "paymentwebhook"

	r := runner.New(workerName)
	if err := r.Init(); err != nil {
		t.Fatal(err)
	}

	c := config.MustRead(r.Conf.Path)
	// init mongo connection
	modelhelper.Initialize(c.Mongo)
	defer modelhelper.Close()

	payment.Initialize(c)

	port := tests.GetFreePort()
	mc := mux.NewConfig(workerName, "localhost", port)
	mc.Debug = r.Conf.Debug
	if r.Conf.Debug {
		stripe.LogLevel = 3
	}
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
}
