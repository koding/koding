package metrics

import (
	"sync"

	gometrics "github.com/rcrowley/go-metrics"
)

type Metrics struct {
	// default registery for our metrics
	Registry gometrics.Registry

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
		Registry: gometrics.NewRegistry(),
		Timers:   Timers{},
		Counters: Counters{},
		Prefix:   prefix,
	}
}

type Timers map[string]gometrics.Timer

type Counters map[string]gometrics.Counter

func (m *Metrics) GetTimer(timerName string) gometrics.Timer {
	m.Lock()
	defer m.Unlock()

	prefixedTimerName := m.Prefix + "_" + timerName
	timer, exists := m.Timers[prefixedTimerName]
	if !exists {
		timer = gometrics.NewTimer()
		m.Registry.Register(prefixedTimerName, timer)

		m.Timers[prefixedTimerName] = timer
	}

	return m.Timers[prefixedTimerName]
}

func (m *Metrics) GetCounter(counterName string) gometrics.Counter {
	m.Lock()
	defer m.Unlock()

	prefixedCounterName := m.Prefix + "_" + counterName
	counter, exists := m.Counters[prefixedCounterName]
	if !exists {
		counter = gometrics.NewCounter()
		m.Registry.Register(prefixedCounterName, counter)

		m.Counters[prefixedCounterName] = counter
	}

	return m.Counters[prefixedCounterName]
}
