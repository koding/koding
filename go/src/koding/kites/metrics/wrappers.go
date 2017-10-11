package metrics

import (
	"bufio"
	"fmt"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/koding/kite"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
)

// WrapKiteHandler wraps the kite handlers adds metrics middlewares.
func WrapKiteHandler(dd *dogstatsd.Client, metricName string, handler kite.HandlerFunc) kite.HandlerFunc {
	register(dd.Namespace, metricName)
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
	register(dd.Namespace, metricName)
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

// RegisterCLICommand registers given command to metrics dashboard.
func RegisterCLICommand(m *Metrics, args ...string) {
	if len(args) == 0 || m == nil || m.Datadog == nil {
		return
	}

	register(m.Datadog.Namespace, strings.Join(args, "_"))
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

// Flush implements http.Flusher interface
func (r *responseRecorder) Flush() {
	rr, ok := r.ResponseWriter.(http.Flusher)
	if ok {
		rr.Flush()
	}
}

// Hijack implements http.Hijacker interface
func (r *responseRecorder) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	hj, ok := r.ResponseWriter.(http.Hijacker)
	if !ok {
		return nil, nil, fmt.Errorf("responseWriter doesn't support hijacking: %T", r.ResponseWriter)
	}

	return hj.Hijack()
}

// Push implements http.Pusher interface
func (r *responseRecorder) Push(target string, opts *http.PushOptions) error {
	p, ok := r.ResponseWriter.(http.Pusher)
	if !ok {
		return fmt.Errorf("responseWriter doesn't support http.Pusher: %T", r.ResponseWriter)
	}

	return p.Push(target, opts)
}

// TODO: check possibility of implementing http.CloseNotifier
