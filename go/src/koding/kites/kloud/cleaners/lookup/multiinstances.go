package lookup

import (
	"bytes"
	"fmt"
	"koding/kites/kloud/api/amazon"
	"sync"
	"text/tabwriter"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/koding/logging"
)

// MultiInstances represents EC2 instance list per region.
type MultiInstances struct {
	m map[*amazon.Client]Instances // read-only, mutated only by NewMultiInstance
}

// NewMultiInstances fetches EC2 instance list from each region.
func NewMultiInstances(clients *amazon.Clients, log logging.Logger) *MultiInstances {
	if log == nil {
		log = defaultLogger
	}
	var m = newMultiInstances()
	var wg sync.WaitGroup
	var mu sync.Mutex // protects m.m
	for region, client := range clients.Regions() {
		wg.Add(1)
		go func(region string, client *amazon.Client) {
			defer wg.Done()
			instances, err := client.Instances()
			if err != nil {
				log.Error("[%s] fetching instances error: %s", region, err)
				return
			}
			log.Info("[%s] fetched %d instances", region, len(instances))
			i := make(Instances, len(instances))
			for _, instance := range instances {
				i[aws.StringValue(instance.InstanceId)] = instance
			}
			var ok bool
			mu.Lock()
			if _, ok = m.m[client]; !ok {
				m.m[client] = i
			}
			mu.Unlock()
			if ok {
				panic(fmt.Errorf("[%s] duplicated client=%p: %+v", region, client, i))
			}
		}(region, client)
	}
	wg.Wait()
	return m
}

// NewMultiInstancesMap gives new MultiInstances which is a copy of
// the given instanceMap.
func NewMultiInstancesMap(instanceMap map[*amazon.Client]Instances) *MultiInstances {
	m := newMultiInstances()
	for client, instances := range instanceMap {
		m.m[client] = instances
	}
	return m
}

func newMultiInstances() *MultiInstances {
	return &MultiInstances{
		m: make(map[*amazon.Client]Instances),
	}
}

func MergeMultiInstances(ms ...map[*amazon.Client]Instances) *MultiInstances {
	merged := newMultiInstances()

	for _, m := range ms {
		for client, instances := range m {
			i, ok := merged.m[client]
			if !ok {
				i = make(Instances, len(instances))
			}
			for id, instance := range instances {
				i[id] = instance
			}
			merged.m[client] = i
		}
	}

	return merged
}

// WithTag filters out instances which contains that particular tag's key and
// value
func (m *MultiInstances) WithTag(key string, values ...string) *MultiInstances {
	filtered := newMultiInstances()
	for client, instances := range m.m {
		filtered.m[client] = instances.WithTag(key, values...)
	}
	return filtered
}

// OlderThan filters out instances that are older than the given duration.
func (m *MultiInstances) OlderThan(duration time.Duration) *MultiInstances {
	filtered := newMultiInstances()
	for client, instances := range m.m {
		filtered.m[client] = instances.OlderThan(duration)
	}
	return filtered
}

// States filters out instances which that particular state
func (m *MultiInstances) States(states ...string) *MultiInstances {
	filtered := newMultiInstances()
	for client, instances := range m.m {
		filtered.m[client] = instances.States(states...)
	}
	return filtered
}

// Only returns a new filtered MultiInstances struct with the given ids only.
func (m *MultiInstances) Only(ids ...string) *MultiInstances {
	filtered := newMultiInstances()
	for client, instances := range m.m {
		filteredInstances := make(Instances, 0)

		for _, id := range ids {
			instance, ok := instances[id]
			if !ok {
				continue
			}

			filteredInstances[id] = instance
		}

		filtered.m[client] = filteredInstances
	}
	return filtered
}

func (m *MultiInstances) Iter(fn func(client *amazon.Client, instances Instances)) {
	for client, instances := range m.m {
		fn(client, instances)
	}
}

// Has returns true if the given ids exists.
func (m MultiInstances) Has(id string) bool {
	for _, instances := range m.m {
		if instances.Has(id) {
			return true
		}
	}
	return false
}

// TerminateAll terminates all instances
func (m *MultiInstances) TerminateAll() {
	if len(m.m) == 0 {
		return
	}

	var wg sync.WaitGroup

	for client, instances := range m.m {
		wg.Add(1)

		go func(client *amazon.Client, instances Instances) {
			defer wg.Done()
			instances.TerminateAll(client)
		}(client, instances)
	}

	wg.Wait()
}

// TerminateAll terminates all instances
func (m *MultiInstances) StopAll() {
	if len(m.m) == 0 {
		return
	}

	var wg sync.WaitGroup

	for client, instances := range m.m {
		wg.Add(1)

		go func(client *amazon.Client, instances Instances) {
			defer wg.Done()
			instances.StopAll(client)
		}(client, instances)
	}

	wg.Wait()
}

// String representation of MultiInstances
func (m *MultiInstances) String() string {
	fmt.Printf("\n\n")
	w := new(tabwriter.Writer)

	buf := new(bytes.Buffer)
	w.Init(buf, 0, 8, 0, '\t', 0)

	total := 0
	for client, instances := range m.m {
		fmt.Fprintf(w, "[%s]\t total instances: %+v \n", client.Region, len(instances))
		total += len(instances)
	}

	fmt.Fprintln(w)
	w.Flush()

	return buf.String()
}

// Total return the number of al instances
func (m *MultiInstances) Total() int {
	total := 0
	for _, instances := range m.m {
		total += len(instances)
	}
	return total
}

// Ids returns the list of ids of all instances.
func (m *MultiInstances) Ids() []string {
	ids := make([]string, 0)

	for _, instances := range m.m {
		ids = append(ids, instances.Ids()...)
	}

	return ids
}
