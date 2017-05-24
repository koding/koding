package metrics

import (
	"bytes"
	"io"
	"net"
	"net/http"
	"os"

	"github.com/koding/kite"
)

// Publisher sends DD events to agent.
type Publisher struct {
	conn            io.WriteCloser
	metricsEndpoint string
}

// NewPublisherWithConn creates new Publisher for sending the incoming events to
// DataDog agent.
func NewPublisherWithConn(conn io.WriteCloser, metricsEndpoint string) *Publisher {
	return &Publisher{
		conn:            conn,
		metricsEndpoint: metricsEndpoint,
	}
}

// NewPublisher creates a new publisher with default DD agent address.
func NewPublisher(metricsEndpoint string) (*Publisher, error) {
	udpAddr, err := net.ResolveUDPAddr("udp", "127.0.0.1:8125")
	if err != nil {
		return nil, err
	}

	conn, err := net.DialUDP("udp", nil, udpAddr)
	if err != nil {
		return nil, err
	}

	return NewPublisherWithConn(conn, metricsEndpoint), nil
}

// PublishRequest represents a request type for "metrics.publish" kloud's
// kite method.
type PublishRequest struct {
	Data GzippedPayload `json:"data"`
}

// Pattern returns the endpoint name for kite.
func (Publisher) Pattern() string {
	return "metrics.publish"
}

// Publish is a kite.Handler for "metrics.publish" kite method.
func (p *Publisher) Publish(r *kite.Request) (interface{}, error) {
	var req PublishRequest
	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	for _, data := range req.Data {
		_, err := p.conn.Write(data)
		if err == nil {
			continue
		}

		if errP, ok := err.(*net.OpError); ok {
			if _, ok := errP.Err.(*os.SyscallError); ok {
				continue
			}
		}

		return nil, err
	}

	go func() {
		if _, err := http.Post(p.metricsEndpoint, "application/json", bytes.NewReader(r.Args.Raw)); err != nil {
			r.LocalKite.Log.Error("Err while publishing metrics: %s", err)
		}
	}()

	return nil, nil
}

// Close closes the underlying connection.
func (p *Publisher) Close() error {
	return p.conn.Close()
}
