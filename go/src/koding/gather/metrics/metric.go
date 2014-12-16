package metrics

import "sync"

type Registry struct {
	Items []*Metric
	Mutex *sync.Mutex
}

type Metric struct {
	Name      string
	Collector Collector
	Output    func([]byte) ([]byte, error)
}

func (m *Metric) Run() ([]byte, error) {
	output, err := m.Collector.Run()
	if err != nil {
		return nil, err
	}

	return m.Output(output)
}

func RegisterMetric(registry *Registry, metric *Metric) {
	registry.Mutex.Lock()
	registry.Items = append(registry.Items, metric)
	registry.Mutex.Unlock()
}
