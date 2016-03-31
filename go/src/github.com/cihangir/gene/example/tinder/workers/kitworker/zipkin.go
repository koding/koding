package kitworker

import (
	"strings"
	"time"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/tracing/zipkin"
)

type ZipkinConf struct {
	// Address holds Zipkin Host Address, should be a TCP endpoint of the form
	// "host:port".
	Address string

	// Timeout is passed to the Thrift dial function NewTSocketFromAddrTimeout.
	Timeout time.Duration

	// BatchSize and batchInterval control the maximum size and interval of a
	// batch of spans as soon as either limit is reached, the batch is sent.
	BatchSize     int
	BatchInterval time.Duration
}

// NewZipkinCollector creates a new Zipkin based ScribeCollector as tracing data
// collector
func NewZipkinCollector(c *ZipkinConf, logger log.Logger) (zipkin.Collector, error) {
	tracingLogger := log.NewContext(logger).With("component", "tracing")
	zipkinLogger := log.NewContext(tracingLogger).With("component", "zipkin")

	if int64(c.Timeout) == 0 {
		c.Timeout = time.Second
	}

	if (c.BatchInterval) == 0 {
		c.BatchInterval = time.Second
	}

	if c.BatchSize == 0 {
		c.BatchSize = 10
	}

	return zipkin.NewScribeCollector(
		c.Address,
		c.Timeout,
		zipkin.ScribeBatchSize(c.BatchSize),
		zipkin.ScribeBatchInterval(c.BatchInterval),
		zipkin.ScribeLogger(zipkinLogger),
	)
}

// NewLoggingCollector creates a tracer which only logs to given logger
func NewLoggingCollector(logger log.Logger) loggingCollector {
	return loggingCollector{logger}
}

type loggingCollector struct{ log.Logger }

// Collect implements Collector interface
func (c loggingCollector) Collect(s *zipkin.Span) error {
	annotations := s.Encode().GetAnnotations()
	values := make([]string, len(annotations))
	for i, a := range annotations {
		values[i] = a.Value
	}
	_ = c.Logger.Log(
		"trace_id", s.TraceID(),
		"span_id", s.SpanID(),
		"parent_span_id", s.ParentSpanID(),
		"annotations", strings.Join(values, " "),
	)
	return nil
}
