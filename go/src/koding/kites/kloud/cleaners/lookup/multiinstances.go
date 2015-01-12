package lookup

import (
	"bytes"
	"fmt"
	"koding/kites/kloud/multiec2"
	"sync"
	"text/tabwriter"
	"time"

	"github.com/mitchellh/goamz/ec2"
)

// MultiInstances represents a map of Instances bound to a region.
type MultiInstances struct {
	mu      sync.Mutex
	m       map[*ec2.EC2]Instances
	clients *multiec2.Clients
}

func NewMultiInstanes(clients *multiec2.Clients) *MultiInstances {
	return &MultiInstances{
		m:       make(map[*ec2.EC2]Instances, 0),
		clients: clients,
	}
}

func (m *MultiInstances) Add(client *ec2.EC2, instances Instances) {
	m.mu.Lock()
	m.m[client] = instances
	m.mu.Unlock()
}

// WithTag filters out instances which contains that particular tag's key and
// value
func (m *MultiInstances) WithTag(key string, values ...string) *MultiInstances {
	m.mu.Lock()
	defer m.mu.Unlock()

	filtered := NewMultiInstanes(m.clients)
	for client, instances := range m.m {
		filtered.m[client] = instances.WithTag(key, values...)
	}
	return filtered
}

// OlderThan filters out instances that are older than the given duration.
func (m *MultiInstances) OlderThan(duration time.Duration) *MultiInstances {
	m.mu.Lock()
	defer m.mu.Unlock()

	filtered := NewMultiInstanes(m.clients)
	for client, instances := range m.m {
		filtered.m[client] = instances.OlderThan(duration)
	}
	return filtered
}

// States filters out instances which that particular state
func (m *MultiInstances) States(states ...string) *MultiInstances {
	m.mu.Lock()
	defer m.mu.Unlock()

	filtered := NewMultiInstanes(m.clients)
	for client, instances := range m.m {
		filtered.m[client] = instances.States(states...)
	}
	return filtered
}

func (m *MultiInstances) Iter(fn func(client *ec2.EC2, instances Instances)) {
	m.mu.Lock()
	defer m.mu.Unlock()

	for client, instances := range m.m {
		fn(client, instances)
	}
}

// Has returns true if the given ids exists.
func (m *MultiInstances) Has(id string) bool {
	m.mu.Lock()
	defer m.mu.Unlock()

	for _, instances := range m.m {
		if instances.Has(id) {
			return true
		}
	}
	return false
}

// Delete deletes the instance with the given Id from the instances list of the
// given region
func (m *MultiInstances) Delete(region, id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	client, err := m.clients.Region(region)
	if err != nil {
		return err
	}

	instances, ok := m.m[client]
	if !ok {
		return fmt.Errorf("no instances for client %v", client)
	}

	instances.Delete(id)
	m.m[client] = instances

	return nil
}

// TerminateAll terminates all instances
func (m *MultiInstances) TerminateAll() {
	m.mu.Lock()
	defer m.mu.Unlock()

	if len(m.m) == 0 {
		return
	}

	var wg sync.WaitGroup

	for client, instances := range m.m {
		wg.Add(1)

		go func(client *ec2.EC2, instances Instances) {
			instances.TerminateAll(client)
			wg.Done()
		}(client, instances)
	}

	wg.Wait()
}

// String representation of MultiInstances
func (m *MultiInstances) String() string {
	m.mu.Lock()
	defer m.mu.Unlock()

	fmt.Printf("\n\n")
	w := new(tabwriter.Writer)

	buf := new(bytes.Buffer)
	w.Init(buf, 0, 8, 0, '\t', 0)

	total := 0
	for client, instances := range m.m {
		region := client.Region.Name
		fmt.Fprintf(w, "[%s]\t total instances: %+v \n", region, len(instances))
		total += len(instances)
	}

	fmt.Fprintln(w)
	w.Flush()

	return buf.String()
}

// Total return the number of al instances
func (m *MultiInstances) Total() int {
	m.mu.Lock()
	defer m.mu.Unlock()

	total := 0
	for _, instances := range m.m {
		total += len(instances)
	}
	return total
}
