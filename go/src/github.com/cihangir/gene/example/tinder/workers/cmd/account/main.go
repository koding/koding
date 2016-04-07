package main

import (
	"flag"
	"net/http"
	"os"
	"time"

	"github.com/cihangir/gene/example/tinder/workers/account"
	"github.com/cihangir/gene/example/tinder/workers/kitworker"
	"golang.org/x/net/context"

	"github.com/go-kit/kit/loadbalancer"
	"github.com/go-kit/kit/loadbalancer/static"
	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/metrics"
)

func main() {
	var (
		listen = flag.String("listen", ":8080", "HTTP listen address")
	)
	flag.Parse()

	logger := log.NewLogfmtLogger(os.Stderr)
	logger = log.NewContext(logger).With("listen", *listen).With("caller", log.DefaultCaller)

	transportLogger := log.NewContext(logger).With("transport", "HTTP/JSON")
	tracingLogger := log.NewContext(transportLogger).With("component", "tracing")
	zipkinLogger := log.NewContext(tracingLogger).With("component", "zipkin")

	ctx := context.Background()

	c := &kitworker.ZipkinConf{
		Address:       ":5000",
		Timeout:       time.Second,
		BatchSize:     10,
		BatchInterval: time.Second,
	}

	collector, err := kitworker.NewZipkinCollector(c, logger)
	if err != nil {
		_ = zipkinLogger.Log("err", err)
	}

	m, err := kitworker.NewMetric("127.0.0.1:8125", metrics.Field{Key: "key", Value: "value"})
	if err != nil {
		panic(err)
	}

	serverOpts := &kitworker.ServerOption{
		Host:            "localhost:3000",
		ZipkinCollector: collector,

		LogErrors:   true,
		LogRequests: true,

		Latency: m.Histogram("tinder_api_account_service_request_histogram"),
		Counter: m.Counter("tinder_api_account_service_request_count"),
	}

	profileApiEndpoints := []string{
		"profile1.tinder_api.tinder.com",
		"profile2.tinder_api.tinder.com",
	}

	lbCreator := func(factory loadbalancer.Factory) loadbalancer.LoadBalancer {
		publisher := static.NewPublisher(
			profileApiEndpoints,
			factory,
			logger,
		)

		return loadbalancer.NewRoundRobin(publisher)
	}

	hostName, err := os.Hostname()
	if err != nil {
		hostName = "localhost"
	}

	clientOpts := &kitworker.ClientOption{
		Host:                hostName + ":" + *listen,
		ZipkinCollector:     collector,
		QPS:                 100,
		LoadBalancerCreator: lbCreator,
	}

	profileService := account.NewAccountClient(
		clientOpts,
		logger,
	)

	ctx = context.WithValue(ctx, "accountService", profileService)

	svc := account.NewAccount()

	account.RegisterHandlers(ctx, svc, serverOpts, logger)

	_ = logger.Log("msg", "HTTP", "addr", *listen)
	_ = logger.Log("err", http.ListenAndServe(*listen, nil))
}
