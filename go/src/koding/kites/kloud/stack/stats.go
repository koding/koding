package stack

import (
	"koding/kites/kloud/contexthelper/request"
	"time"

	"github.com/koding/logging"
	"golang.org/x/net/context"
)

var RequestTraceKey struct {
	byte `key:"requestTrace"`
}

func RequestTraceFromContext(ctx context.Context) (*RequestTrace, bool) {
	rt, ok := ctx.Value(RequestTraceKey).(*RequestTrace)
	return rt, ok
}

type RequestTrace struct {
	start    time.Time
	tags     []string
	histFunc func(string, float64, []string, float64) error
	log      logging.Logger
	hijacked bool
}

func (rt *RequestTrace) Hijack() {
	rt.hijacked = true
}

func (rt *RequestTrace) Send() {
	if rt.histFunc == nil {
		return
	}

	dur := float64(time.Now().Sub(rt.start)) / float64(time.Millisecond)

	rt.log.Debug("sending metric for tags %v: %s", rt.tags, dur)

	err := rt.histFunc("request.time", dur, rt.tags, 1.0)
	if err != nil {
		rt.log.Warning("failure sending trace for %v: %s", rt.tags, err)
	}
}

func (k *Kloud) traceRequest(ctx context.Context, tags []string) context.Context {
	if r, ok := request.FromContext(ctx); ok {
		tags = append(tags, "action:"+r.Method)
	}

	if traceID, ok := ctx.Value(TraceKey).(string); ok {
		tags = append(tags, "trace:"+traceID)
	}

	return context.WithValue(ctx, RequestTraceKey, &RequestTrace{
		start:    time.Now(),
		tags:     tags,
		histFunc: k.Metrics.Histogram,
		log:      k.Log,
	})
}

func (k *Kloud) send(ctx context.Context) {
	rt, ok := RequestTraceFromContext(ctx)
	if !ok {
		return
	}

	// if response is async and the result is being communicated
	// back with eventer, then RequestTrace is hijacked by the
	// handler and executed after the async op is done
	if rt.hijacked {
		return
	}

	rt.Send()
}
