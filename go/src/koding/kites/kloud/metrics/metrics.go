package metrics

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"time"

	"golang.org/x/net/context/ctxhttp"

	"github.com/cenkalti/backoff"
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
	argOne := r.Args.One()
	if err := argOne.Unmarshal(&req); err != nil {
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

	go publishToCountly(p.metricsEndpoint, argOne.Raw, r.LocalKite.Log)

	return nil, nil
}

// Close closes the underlying connection.
func (p *Publisher) Close() error {
	return p.conn.Close()
}

func publishToCountly(url string, r []byte, log kite.Logger) error {
	req := bytes.NewReader(r)

	ticker := backoff.NewTicker(newBackoff())
	defer ticker.Stop()

	var err error
	var retry bool
	for range ticker.C {
		// each request should not take more than 5 sec
		ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
		defer cancel()

		if _, err := req.Seek(0, io.SeekStart); err != nil {
			return fmt.Errorf("failed to seek body: %v", err)
		}

		retry, err = shouldRetry(ctxhttp.Post(ctx, nil, url, "application/json", req))
		if err != nil {
			log.Error("Err while publishing metrics: %s", err)
		}

		if retry {
			log.Error("err while operating will retry...")
			continue
		}

		break
	}

	return err
}

func shouldRetry(resp *http.Response, err error) (bool, error) {
	if err != nil {
		return true, err
	}
	// Check the response code. We retry on 500-range responses to allow
	// the server time to recover, as 500's are typically not permanent
	// errors and may relate to outages on the server side. This will catch
	// invalid response codes as well, like 0 and 999.
	if resp.StatusCode == 0 || resp.StatusCode >= http.StatusInternalServerError {
		return true, nil
	}

	return false, nil
}

func newBackoff() backoff.BackOff {
	bo := backoff.NewExponentialBackOff()
	bo.InitialInterval = time.Millisecond * 250
	bo.MaxInterval = time.Second * 1
	bo.MaxElapsedTime = time.Minute * 2
	return bo
}
