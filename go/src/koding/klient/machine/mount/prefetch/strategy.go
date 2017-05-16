package prefetch

import (
	"sort"
	"strings"

	"koding/klient/machine/index"
)

// DefaultStrategy defines a default set of prefetchers.
var DefaultStrategy = Strategy{
	// TODO(rjeczalik): disabled due to #11135
	// "git": Git{},
	"all": All{},
}

// Strategy defines a way of choosing proper prefetching strategy.
type Strategy map[string]Prefetcher

// Available returns all available prefetcher names that can be used on caller's
// localhost. Returned names are sorted by prefetcher wights. From highest to
// lowest.
func (s Strategy) Available() (av []string) {
	// Select available prefetchers and put their names to weight map.
	byWeight := make(map[int][]string)
	for name, pref := range s {
		if !pref.Available() {
			continue
		}
		w := pref.Weight()

		names := append(byWeight[w], name)
		sort.Strings(names)
		byWeight[w] = names
	}

	// Get unique weights.
	weights := make([]int, 0, len(byWeight))
	for w := range byWeight {
		weights = append(weights, w)
	}

	// Put names to available slice in weight decreasing order.
	sort.Sort(sort.Reverse(sort.IntSlice(weights)))
	for _, w := range weights {
		names := byWeight[w]
		for _, name := range names {
			av = append(av, name)
		}
	}

	return av
}

// Select creates prefetch object with the best available strategy.
func (s Strategy) Select(opts Options, av []string, idx *index.Index) Prefetch {
	p := Prefetch{
		Options: opts,
		WorkDir: strings.TrimRight(opts.DestinationPath, "/"),
	}

	if p.SourcePath != "" && !strings.HasSuffix(p.SourcePath, "/") {
		p.SourcePath += "/"
	}
	if p.DestinationPath != "" && !strings.HasSuffix(p.DestinationPath, "/") {
		p.DestinationPath += "/"
	}

	for _, name := range av {
		pref, ok := s[name]
		if !ok {
			continue
		}

		if suffix, count, diskSize, err := pref.Scan(idx); err == nil {
			p.Strategy = name
			p.SourcePath += suffix
			p.DestinationPath += suffix
			p.Count, p.DiskSize = count, diskSize
			break
		}
	}

	return p
}
