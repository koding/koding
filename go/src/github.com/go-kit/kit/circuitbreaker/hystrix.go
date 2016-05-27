package circuitbreaker

import (
	"github.com/afex/hystrix-go/hystrix"
	"golang.org/x/net/context"

	"github.com/go-kit/kit/endpoint"
)

// Hystrix returns an endpoint.Middleware that implements the circuit
// breaker pattern using the afex/hystrix-go package.
//
// When using this circuit breaker, please configure your commands separately.
//
// See https://godoc.org/github.com/afex/hystrix-go/hystrix for more
// information.
func Hystrix(commandName string) endpoint.Middleware {
	return func(next endpoint.Endpoint) endpoint.Endpoint {
		return func(ctx context.Context, request interface{}) (response interface{}, err error) {
			output := make(chan interface{}, 1)
			errors := hystrix.Go(commandName, func() error {
				resp, err := next(ctx, request)
				if err == nil {
					output <- resp
				}
				return err
			}, nil)

			select {
			case resp := <-output:
				return resp, nil
			case err := <-errors:
				return nil, err
			}
		}
	}
}
