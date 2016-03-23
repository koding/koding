package metrics

import (
	"crypto/rand"
	"os"
	"os/user"
	"time"

	"github.com/segmentio/analytics-go"
)

type EventName string

const (
	DefaultTimeout  = 5 * time.Second
	DefaultInterval = 1 * time.Minute
	SegmentKey      = "2hPHGxJfgsqJ2snTQHL81oDYEYsPAQkK"
)

type Metric struct {
	Name       EventName
	Properties map[string]interface{}
}

type MetricClient struct {
	Destination string
	Interval    time.Duration
	GetId       func() (string, error)
	client      *analytics.Client
}

func NewDefaultClient() *MetricClient {
	client := analytics.New(SegmentKey)
	client.Interval = 10 * time.Second
	client.Size = 0

	return &MetricClient{
		Interval: DefaultInterval,
		client:   client,
		GetId:    getId,
	}
}

func (m *MetricClient) SendMetric(mc *Metric) error {
	id, err := m.GetId()
	if err != nil {
		id = m.randomId()
	}

	err = m.client.Identify(&analytics.Identify{
		UserId: id,
	})
	if err != nil {
		return err
	}

	err = m.client.Track(&analytics.Track{
		Event:      string(mc.Name),
		UserId:     id,
		Properties: mc.Properties,
	})
	if err != nil {
		return err
	}

	return m.client.Close()
}

func (m *MetricClient) StartMountStatusTicker() error {
	return nil
}

func (m *MetricClient) TrackRun(mn string) error {
	mc := &Metric{
		Name: EventRun,
		Properties: map[string]interface{}{
			"machine": mn,
		},
	}

	return m.SendMetric(mc)
}

func (m *MetricClient) TrackRepair(mn string) error {
	mc := &Metric{
		Name: EventRepair,
		Properties: map[string]interface{}{
			"machine": mn,
		},
	}

	return m.SendMetric(mc)
}

func (m *MetricClient) TrackRepairError(mn, errStr string) error {
	mc := &Metric{
		Name: EventRepairFailed,
		Properties: map[string]interface{}{
			"machine": mn,
			"error":   errStr,
		},
	}

	return m.SendMetric(mc)
}

func (m *MetricClient) randomId() string {
	bites := make([]byte, 10)
	if _, err := rand.Read(bites); err != nil {
		return "<unknown>"
	}

	return string(bites)
}

///// helpers

func getId() (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	// in rare cases where we can't get hostname, use what we've
	hostname, err := os.Hostname()
	if err != nil {
		return usr.Username, nil
	}

	return usr.Username + ":" + hostname, nil
}
