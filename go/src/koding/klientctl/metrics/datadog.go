package metrics

import (
	"io"

	statsd "github.com/DataDog/datadog-go/statsd"
)

// NewDataDogClient creates a new DataDog client and stores the events in the given WriteCloser.
func NewDataDogClient(c io.WriteCloser) (*statsd.Client, error) {
	return statsd.NewWithConn(c)
}
