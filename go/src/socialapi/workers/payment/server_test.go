package payment

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net"
	"socialapi/config"
	"socialapi/workers/common/mux"
	paymentapi "socialapi/workers/payment/api"
	"strconv"
	"testing"

	"github.com/koding/runner"
	"github.com/stripe/stripe-go"
)

func withTestServer(t *testing.T, f func(url string)) {
	stripe.Key = ""
	const workerName = "paymentwebhook"

	r := runner.New(workerName)
	if err := r.Init(); err != nil {
		t.Fatal(err.Error())
	}

	c := config.MustRead(r.Conf.Path)

	// init mongo connection
	modelhelper.Initialize(c.Mongo)
	defer modelhelper.Close()

	port := getPort()
	mc := mux.NewConfig(workerName, "localhost", port)
	mc.Debug = r.Conf.Debug
	m := mux.New(mc, r.Log, r.Metrics)

	paymentapi.AddHandlers(m)

	m.Listen()

	go r.Listen()

	f(fmt.Sprintf("http://localhost:%s", port))

	if err := r.Close(); err != nil {
		t.Fatalf("server close errored: %s", err.Error())
	}

	// shutdown server
	m.Close()
}

func getPort() string {
	addr, err := net.ResolveTCPAddr("tcp", "localhost:0")
	if err != nil {
		panic(err)
	}

	l, err := net.ListenTCP("tcp", addr)
	if err != nil {
		panic(err)
	}
	defer l.Close()

	return strconv.Itoa(l.Addr().(*net.TCPAddr).Port)
}
