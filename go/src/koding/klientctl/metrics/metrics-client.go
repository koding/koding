package metrics

import (
	"crypto/rand"
	"io/ioutil"
	"koding/mountcli"
	"log"
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

	client  *analytics.Client
	tickers map[string]*time.Ticker
}

func NewDefaultClient() *MetricClient {
	client := analytics.New(SegmentKey)
	client.Interval = 10 * time.Second
	client.Size = 0
	client.Logger = log.New(ioutil.Discard, "", 0)

	return &MetricClient{
		Interval: DefaultInterval,
		GetId:    getId,
		client:   client,
		tickers:  map[string]*time.Ticker{},
	}
}

func (m *MetricClient) SendMetric(mc *Metric) error {
	id, err := m.GetId()
	if err != nil {
		id = m.randomId()
	}

	if mc.Properties == nil {
		mc.Properties = map[string]interface{}{}
	}

	mc.Properties["timestamp"] = time.Now().UTC()

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

func (m *MetricClient) StartMountStatusTicker(machine string) (err error) {
	var (
		i        int
		failures int
	)

	// stop previous tickers if any
	if ticker, ok := m.tickers[machine]; ok {
		ticker.Stop()
	}

	// start new ticker and save for future use
	ticker := time.NewTicker(m.Interval)
	m.tickers[machine] = ticker

	path, err := mountcli.NewMountcli().FindMountNameByPath(machine)
	if err != nil {
		TrackMountCheckFailure(machine, err.Error())
		return err
	}

	for _ = range ticker.C {
		ms := NewDefaultMountStatus(path)

		// alterate between reading & writing; this is req. since kernel
		// catches file on write, if we read right away, it'll return contents
		// from kernel cache and not from mount like we want it to
		if i%2 == 0 {
			err = ms.Write()
		} else {
			err = ms.CheckContents()
		}

		// we only care about failures and not success
		if err != nil {
			TrackMountCheckFailure(machine, err.Error())
			failures += 1
		}

		// if it errors more than twice, there's no point in continuing
		if failures > 2 {
			return nil
		}

		i += 1
	}

	return nil
}

func (m *MetricClient) StopMountStatusTicker(machine string) {
	if ticker, ok := m.tickers[machine]; ok {
		ticker.Stop()
	}

	delete(m.tickers, machine)
}

///// helpers

func (m *MetricClient) randomId() string {
	bites := make([]byte, 10)
	if _, err := rand.Read(bites); err != nil {
		return "<unknown>"
	}

	return string(bites)
}

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
