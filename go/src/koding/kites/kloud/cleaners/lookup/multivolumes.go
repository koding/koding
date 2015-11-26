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

// MultiVolumes describe volume list per region.
type MultiVolumes struct {
	m map[*amazon.Client]Volumes // read-only, mutated only by NewMultiVolumes
}

// NewMultiVolumes fetches volume list from each region.
func NewMultiVolumes(clients *amazon.Clients, log logging.Logger) *MultiVolumes {
	if log == nil {
		log = defaultLogger
	}
	var m = newMultiVolumes()
	var wg sync.WaitGroup
	var mu sync.Mutex // protects m.m
	for region, client := range clients.Regions() {
		wg.Add(1)
		go func(region string, client *amazon.Client) {
			defer wg.Done()
			volumes, err := client.Volumes()
			if err != nil {
				log.Error("[%s] fetching volumes error: %s", region, err)
				return
			}
			log.Info("[%s] fetched %d volumes", region, len(volumes))
			v := make(Volumes, len(volumes))
			for _, volume := range volumes {
				v[aws.StringValue(volume.VolumeId)] = volume
			}
			var ok bool
			mu.Lock()
			if _, ok = m.m[client]; !ok {
				m.m[client] = v
			}
			mu.Unlock()
			if ok {
				panic(fmt.Errorf("[%s] duplicated client=%p: %+v", region, client, v))
			}
		}(region, client)
	}
	wg.Wait()
	return m
}

func newMultiVolumes() *MultiVolumes {
	return &MultiVolumes{
		m: make(map[*amazon.Client]Volumes),
	}
}

func (m *MultiVolumes) GreaterThan(storage int) *MultiVolumes {
	filtered := newMultiVolumes()
	for client, volumes := range m.m {
		filtered.m[client] = volumes.GreaterThan(storage)
	}
	return filtered
}

// OlderThan filters out volumes that are older than the given duration.
func (m *MultiVolumes) OlderThan(duration time.Duration) *MultiVolumes {
	filtered := newMultiVolumes()
	for client, volumes := range m.m {
		filtered.m[client] = volumes.OlderThan(duration)
	}
	return filtered
}

func (m *MultiVolumes) Status(status string) *MultiVolumes {
	filtered := newMultiVolumes()
	for client, volumes := range m.m {
		filtered.m[client] = volumes.Status(status)
	}
	return filtered
}

func (m *MultiVolumes) Volumes() []Volumes {
	volumes := make([]Volumes, 0, len(m.m))
	for _, v := range m.m {
		volumes = append(volumes, v)
	}
	return volumes
}

// InstanceIds returns a map of volumeIds per region
func (m *MultiVolumes) IntsanceIds() map[*amazon.Client]map[string]string {
	instances := make(map[*amazon.Client]map[string]string, len(m.m))

	for client, volumes := range m.m {
		instances[client] = volumes.InstanceIds()
	}

	return instances
}

// TerminateAll terminates all volumes
func (m *MultiVolumes) TerminateAll() {
	if len(m.m) == 0 {
		return
	}

	var wg sync.WaitGroup

	for client, volumes := range m.m {
		wg.Add(1)
		go func(client *amazon.Client, volumes Volumes) {
			defer wg.Done()
			volumes.TerminateAll(client)
		}(client, volumes)
	}

	wg.Wait()
}

// Total return the number of all volumes
func (m *MultiVolumes) Total() int {
	total := 0
	for _, volumes := range m.m {
		total += len(volumes)
	}
	return total
}

// String representation of MultiVolumes
func (m *MultiVolumes) String() string {
	fmt.Printf("\n\n")
	w := new(tabwriter.Writer)

	buf := new(bytes.Buffer)
	w.Init(buf, 0, 8, 0, '\t', 0)

	total := 0
	for client, volumes := range m.m {
		fmt.Fprintf(w, "[%s]\t total volumes: %+v \n", client.Region, len(volumes))
		total += len(volumes)
	}

	fmt.Fprintln(w)
	w.Flush()

	return buf.String()
}
