package lookup

import (
	"bytes"
	"fmt"
	"sync"
	"text/tabwriter"
	"time"

	"github.com/mitchellh/goamz/ec2"
)

type MultiInstances map[*ec2.EC2]Instances

// WithTag filters out instances which contains that particular tag's key and
// value
func (m MultiInstances) WithTag(key string, values ...string) MultiInstances {
	filtered := make(MultiInstances, 0)
	for client, instances := range m {
		filtered[client] = instances.WithTag(key, values...)
	}
	return filtered
}

// OlderThan filters out instances that are older than the given duration.
func (m MultiInstances) OlderThan(duration time.Duration) MultiInstances {
	filtered := make(MultiInstances, 0)
	for client, instances := range m {
		filtered[client] = instances.OlderThan(duration)
	}
	return filtered
}

// States filters out instances which that particular state
func (m MultiInstances) States(states ...string) MultiInstances {
	filtered := make(MultiInstances, 0)
	for client, instances := range m {
		filtered[client] = instances.States(states...)
	}
	return filtered
}

func (m MultiInstances) Iter(fn func(client *ec2.EC2, instances Instances)) {
	for client, instances := range m {
		fn(client, instances)
	}
}

// Has returns true if the given ids exists.
func (m MultiInstances) Has(id string) bool {
	for _, instances := range m {
		if instances.Has(id) {
			return true
		}
	}
	return false
}

// TerminateAll terminates all instances
func (m MultiInstances) TerminateAll() {
	if len(m) == 0 {
		return
	}

	var wg sync.WaitGroup

	for client, instances := range m {
		wg.Add(1)

		go func(client *ec2.EC2, instances Instances) {
			instances.TerminateAll(client)
			wg.Done()
		}(client, instances)
	}

	wg.Wait()
}

// String representation of MultiInstances
func (m MultiInstances) String() string {
	fmt.Printf("\n\n")
	w := new(tabwriter.Writer)

	buf := new(bytes.Buffer)
	w.Init(buf, 0, 8, 0, '\t', 0)

	total := 0
	for client, instances := range m {
		region := client.Region.Name
		fmt.Fprintf(w, "[%s]\t total instances: %+v \n", region, len(instances))
		total += len(instances)
	}

	fmt.Fprintln(w)
	w.Flush()

	return buf.String()
}

// Total return the number of al instances
func (m MultiInstances) Total() int {
	total := 0
	for _, instances := range m {
		total += len(instances)
	}
	return total
}

// Ids returns the list of ids of all instances.
func (m MultiInstances) Ids() []string {
	ids := make([]string, 0)

	for _, instances := range m {
		ids = append(ids, instances.Ids()...)
	}

	return ids
}

// Only returns a new filtered MultiInstances struct with the given ids only.
func (m MultiInstances) Only(ids ...string) MultiInstances {
	filtered := make(MultiInstances, 0)
	for client, instances := range m {

		filteredInstances := make(Instances, 0)

		for _, id := range ids {
			instance, ok := instances[id]
			if !ok {
				continue
			}

			filteredInstances[id] = instance
		}

		filtered[client] = filteredInstances
	}
	return filtered
}
