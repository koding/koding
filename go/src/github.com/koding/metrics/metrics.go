package metrics

import (
	"sync"

	"github.com/rcrowley/go-metrics"
)

type Metrics struct {
	// default registery for our metrics
	Registry metrics.Registry

	// all timer metrics live here
	Timers Timers

	// all the counters will live here
	Counters Counters

	// prefix of the all metrics, generally app name
	Prefix string

	// for synchronisation purposes
	sync.Mutex
}

func New(prefix string) *Metrics {
	return &Metrics{
		Registry: metrics.NewRegistry(),
		Timers:   Timers{},
		Counters: Counters{},
		Prefix:   prefix,
	}
}

type Timers map[string]metrics.Timer

type Counters map[string]metrics.Counter

func (m *Metrics) GetTimer(timerName string) metrics.Timer {
	m.Lock()
	defer m.Unlock()

	prefixedTimerName := m.Prefix + ":" + timerName
	timer, exists := m.Timers[prefixedTimerName]
	if !exists {
		timer = metrics.NewTimer()
		m.Registry.Register(prefixedTimerName, timer)

		m.Timers[prefixedTimerName] = timer
	}

	return m.Timers[prefixedTimerName]
}

func (m *Metrics) GetCounter(counterName string) metrics.Counter {
	m.Lock()
	defer m.Unlock()

	prefixedCounterName := m.Prefix + ":" + counterName
	counter, exists := m.Counters[prefixedCounterName]
	if !exists {
		counter = metrics.NewCounter()
		m.Registry.Register(prefixedCounterName, counter)

		m.Counters[prefixedCounterName] = counter
	}

	return m.Counters[prefixedCounterName]
}
