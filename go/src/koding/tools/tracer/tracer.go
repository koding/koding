package tracer

import (
	"fmt"
	"io/ioutil"

	"github.com/koding/logging"
)

type Tracer interface {
	Trace(format string, args ...interface{})
}

type LogTracer struct {
	log logging.Logger
}

type FmtTracer struct {
	discard bool
}

func DefaultTracer() Tracer {
	return &FmtTracer{}
}

func DiscardTracer() Tracer {
	return &FmtTracer{discard: true}
}

func (l *LogTracer) Trace(format string, args ...interface{}) {
	l.log.Info(format, args...)
}

func (f *FmtTracer) Trace(format string, args ...interface{}) {
	if f.discard {
		fmt.Fprintf(ioutil.Discard, format, args...)
	} else {
		fmt.Printf(format, args...)
	}
}
