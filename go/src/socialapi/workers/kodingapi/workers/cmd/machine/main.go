package main

import (
	"errors"
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"os"
	"socialapi/config"
	machine "socialapi/workers/kodingapi/workers/machine"
	"strings"

	kitworker "socialapi/workers/kodingapi/workers/kitworker"

	"golang.org/x/net/context"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/metrics"
	httptransport "github.com/go-kit/kit/transport/http"
	"github.com/koding/runner"
)

var (
	ErrTokenNotSet  = errors.New("token is not set")
	ErrInvalidToken = errors.New("invalid token")
)

func getAuthorization(h http.Header) (string, error) {
	authHeader := h.Get("Authorization")
	if authHeader == "" {
		return "", ErrTokenNotSet
	}

	var token string

	if authHeader != "" {
		s := strings.SplitN(authHeader, " ", 2)
		if len(s) != 2 || strings.ToLower(s[0]) != "bearer" {
			return "", ErrInvalidToken
		}
		//Use authorization header token only if token type is bearer else query string access token would be returned
		if len(s) > 0 && strings.ToLower(s[0]) == "bearer" {
			token = s[1]
		}
	}

	return token, nil
}

var Name = "KodingApi"

func main() {

	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	var (
		listen = flag.String("listen", ":8080", "HTTP listen address")
	)
	flag.Parse()

	logger := log.NewLogfmtLogger(os.Stderr)
	logger = log.NewContext(logger).With("listen", *listen).With("caller", log.DefaultCaller)

	ctx := context.Background()

	_, err := kitworker.NewMetric("127.0.0.1:8125", metrics.Field{Key: "key", Value: "value"})
	if err != nil {
		panic(err)
	}

	before := httptransport.ServerBefore(func(ctx context.Context, r *http.Request) context.Context {
		auth, _ := getAuthorization(r.Header)

		return context.WithValue(ctx, "auth", auth)
	})

	serverOpts := &kitworker.ServerOption{
		Host: "localhost:3000",

		LogErrors:   true,
		LogRequests: true,
	}

	serverOpts.ServerOptions = append(serverOpts.ServerOptions, before)

	svc := machine.NewMachine()

	machine.RegisterHandlers(ctx, svc, serverOpts, logger)

	_ = logger.Log("msg", "HTTP", "addr", *listen)
	_ = logger.Log("err", http.ListenAndServe(*listen, nil))
}
