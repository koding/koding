package metrics

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
	"github.com/codegangsta/cli"
	"github.com/koding/kite"
)

// WrapKiteHandler wraps the kite handlers adds metrics middlewares.
func WrapKiteHandler(dd *dogstatsd.Client, metricName string, handler kite.HandlerFunc) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		start := time.Now()
		resp, err := handler.ServeKite(r)
		dur := time.Since(start)

		var tags []string
		tags = AppendTag(tags, "success", err == nil)
		tags = AppendTag(tags, "method", r.Method)
		tags = AppendTag(tags, "username", r.Username)
		tags = AppendTag(tags, "request_type", "kite")

		if err != nil {
			msg := err.Error()
			if len(msg) > 20 {
				msg = msg[:20]
			}
			tags = AppendTag(tags, "err_message", msg)
		}

		go func() {
			dd.Count(metricName+"_call_count", 1, tags, 1)
			dd.Timing(metricName+"_timing", dur, tags, 1)
		}()

		return resp, err
	}
}

// WrapHTTPHandler wraps the http handlers adds metrics middlewares.
func WrapHTTPHandler(dd *dogstatsd.Client, metricName string, handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rr := newResponseRecorder(w)
		handler(rr, r)
		dur := time.Since(start)

		var tags []string
		tags = AppendTag(tags, "code", rr.code)
		tags = AppendTag(tags, "request_type", "http")

		go func() {
			dd.Count(metricName+"_call_count", 1, tags, 1)
			dd.Timing(metricName+"_timing", dur, tags, 1)
		}()
	}
}

// WrapCLIActions injects the metrics as middlewares into cli.Commands Actions.
func WrapCLIActions(dd *dogstatsd.Client, commands []cli.Command, tagsFn func(string) []string) []cli.Command {
	for i, command := range commands {
		if command.Action != nil {
			commands[i].Action = WrapCLIAction(dd, command.Action.(cli.ActionFunc), tagsFn)
		}
		commands[i].Subcommands = WrapCLIActions(dd, command.Subcommands, tagsFn)
	}

	return commands
}

// WrapCLIAction wraps the actions of cli commands and adds metrics middlewares.
func WrapCLIAction(dd *dogstatsd.Client, action cli.ActionFunc, tagsFn func(string) []string) cli.ActionFunc {
	return func(c *cli.Context) error {
		fullName := c.Command.FullName()
		metricName := strings.Replace(fullName, " ", "_", -1)

		start := time.Now()
		err := action(c)
		dur := time.Since(start)

		tags := tagsFn(fullName)
		tags = AppendTag(tags, "success", err == nil)
		tags = AppendTag(tags, "request_type", "cli")

		if err != nil {
			msg := err.Error()
			if len(msg) > 20 {
				msg = msg[:20]
			}
			tags = AppendTag(tags, "err_message", msg)
		}

		go func() {
			dd.Count(metricName+"_call_count", 1, tags, 1)
			dd.Timing(metricName+"_timing", dur, tags, 1)
		}()

		return err
	}
}

// AppendTag appends DD tags with formatting.
func AppendTag(tags []string, key string, val interface{}) []string {
	// http://docs.datadoghq.com/guides/dogstatsd/#datagram-format
	tag := fmt.Sprintf("%s:%v", key, val)
	tag = strings.Replace(tag, " ", "_", -1)
	return append(tags, tag)
}

type responseRecorder struct {
	http.ResponseWriter
	code int
}

func newResponseRecorder(w http.ResponseWriter) *responseRecorder {
	return &responseRecorder{
		ResponseWriter: w,
		code:           200,
	}
}

func (r *responseRecorder) WriteHeader(status int) {
	r.code = status
	r.ResponseWriter.WriteHeader(status)
}
