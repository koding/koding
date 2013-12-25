package graphite

import (
	"bytes"
	"fmt"
	"log"
	"net"
	"time"
)

// Graphite is a struct that defines the relevant properties of a graphite
// connection
type Graphite struct {
	Host    string
	Port    int
	Timeout time.Duration
	conn    net.Conn
	nop     bool
}

// Metric is a struct that defines the relevant properties of a graphite metric
type Metric struct {
	Name      string
	Value     string
	Timestamp int64
}

// defaultTimeout is the default number of seconds that we're willing to wait
// before forcing the connection establishment to fail
const defaultTimeout = 5

// IsNop is a getter for *graphite.Graphite.nop
func (graphite *Graphite) IsNop() bool {
	if graphite.nop {
		return true
	} else {
		return false
	}
}

// Given a Graphite struct, Connect populates the Graphite.conn field with an
// appropriate TCP connection
func (graphite *Graphite) Connect() error {
	if !graphite.IsNop() {
		address := fmt.Sprintf("%s:%d", graphite.Host, graphite.Port)

		if graphite.Timeout == 0 {
			graphite.Timeout = defaultTimeout * time.Second
		}

		conn, err := net.DialTimeout("tcp", address, graphite.Timeout)
		if err != nil {
			return err
		}

		graphite.conn = conn
	}

	return nil
}

// Given a Metric struct, the SendMetric method sends the supplied metric to the
// Graphite connection that the method is called upon
func (graphite *Graphite) SendMetric(metric Metric) {
	if metric.Timestamp == 0 {
		metric.Timestamp = time.Now().Unix()
	}

	graphite.sendMetric(metric)
}

// The SimpleSend method can be used to just pass a metric name and value and
// have it be sent to the Graphite host with the current timestamp
func (graphite *Graphite) SimpleSend(stat string, value string) error {
	metric := Metric{Name: stat, Value: value, Timestamp: time.Now().Unix()}
	err := graphite.sendMetric(metric)
	if err != nil {
		return err
	}
	return nil
}

// sendMetric is an internal function that is used to write to the TCP
// connection in order to communicate a metric to the remote Graphite host
func (graphite *Graphite) sendMetric(metric Metric) error {
	if !graphite.IsNop() {
		buf := bytes.NewBufferString(fmt.Sprintf("%s %s %d\n", metric.Name, metric.Value, metric.Timestamp))
		_, err := graphite.conn.Write(buf.Bytes())
		if err != nil {
			return err
		}
	} else {
		log.Printf("Graphite: %s %s %d\n", metric.Name, metric.Value, metric.Timestamp)
	}

	return nil
}

// NewGraphiteHost is a factory method that's used to create a new Graphite
// connection given a hostname and a port number
func NewGraphite(host string, port int) (*Graphite, error) {
	Graphite := &Graphite{Host: host, Port: port}
	err := Graphite.Connect()
	if err != nil {
		return nil, err
	}

	return Graphite, nil
}

// NewGraphiteNop is a factory method that returns a Graphite struct but will
// not actually try to send any packets to a remote host and, instead, will just
// log. This is useful if you want to use Graphite in a project but don't want
// to make Graphite a requirement for the project.
func NewGraphiteNop(host string, port int) *Graphite {
	graphiteNop := &Graphite{Host: host, Port: port, nop: true}
	return graphiteNop
}
