package metrics

import (
	"crypto/rand"
	"fmt"
	"io/ioutil"
	"koding/mountcli"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/user"
	"time"

	"github.com/segmentio/analytics-go"
)

type EventName string

const (
	DefaultTimeout       = 5 * time.Second
	DefaultInterval      = 1 * time.Minute
	DefaultLimitFailures = 5
	SegmentKey           = "2hPHGxJfgsqJ2snTQHL81oDYEYsPAQkK"
)

type Metric struct {
	Name       EventName
	Properties map[string]interface{}
}

type MetricClient struct {
	Destination   string
	Interval      time.Duration
	GetId         func() (string, error)
	LimitFailures int

	client  *analytics.Client
	tickers map[string]*time.Ticker
}

func NewDefaultClient() *MetricClient {
	client := analytics.New(SegmentKey)
	client.Interval = DefaultInterval
	client.Size = 0
	client.Logger = log.New(ioutil.Discard, "", 0)

	return &MetricClient{
		Interval:      DefaultInterval,
		GetId:         getId,
		LimitFailures: DefaultLimitFailures,
		client:        client,
		tickers:       map[string]*time.Ticker{},
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

func (m *MetricClient) TriggerMountStatusStart(mount string) error {
	return m.triggerMountStatus("start", mount)
}

func (m *MetricClient) TriggerMountStatusStop(mount string) error {
	return m.triggerMountStatus("stop", mount)
}

func (m *MetricClient) triggerMountStatus(action, mount string) error {
	if err := forkAndStart(); err != nil {
		return err
	}

	u, err := url.Parse(fmt.Sprintf("http://localhost:%s", DefaultPort))

	if err != nil {
		return err
	}

	q := u.Query()
	q.Set("machine", mount)
	q.Set("action", action)

	u.RawQuery = q.Encode()

	resp, err := http.Post(u.String(), "", nil)
	if err != nil {
		return err
	}

	if resp.StatusCode != 200 {
		return fmt.Errorf("Expected 200, but received %s", resp.StatusCode)
	}

	return nil
}

func (m *MetricClient) StartMountStatusTicker(mount string) (err error) {
	var (
		i        int
		failures int
	)

	// stop previous tickers if any
	m.StopMountStatusTicker(mount)

	// start new ticker and save for future use
	ticker := time.NewTicker(m.Interval)
	m.tickers[mount] = ticker

	path, err := mountcli.NewMountcli().FindMountedPathByName(mount)
	if err != nil {
		TrackMountCheckFailure(mount, err.Error())
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
			TrackMountCheckFailure(mount, err.Error())
			failures += 1
		}

		// if it errors more than limit, return from ticker
		if failures > m.LimitFailures {
			return nil
		}

		i += 1
	}

	return nil
}

func (m *MetricClient) StopMountStatusTicker(mount string) {
	if ticker, ok := m.tickers[mount]; ok {
		ticker.Stop()
	}

	delete(m.tickers, mount)
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
