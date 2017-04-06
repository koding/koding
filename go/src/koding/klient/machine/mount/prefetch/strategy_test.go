package prefetch_test

import (
	"errors"
	"reflect"
	"testing"

	"koding/klient/machine/index"
	"koding/klient/machine/mount/prefetch"
)

func TestStrategy(t *testing.T) {
	s := prefetch.Strategy{
		"A": &dummy{
			available: true,
			weight:    50,
			suffix:    "A",
			err:       nil,
		},
		"B": &dummy{
			available: false,
			weight:    100,
			suffix:    "B",
			err:       nil,
		},
		"C": &dummy{
			available: true,
			weight:    200,
			suffix:    "C",
			err:       errors.New("none"),
		},
		"D": &dummy{
			available: true,
			weight:    10,
			suffix:    "D",
			err:       nil,
		},
		"E": &dummy{
			available: true,
			weight:    10,
			suffix:    "E",
			err:       nil,
		},
	}

	wantAv := []string{"C", "A", "D", "E"}
	if av := s.Available(); !reflect.DeepEqual(av, wantAv) {
		t.Fatalf("want available prefetchers = %v; got %v", wantAv, av)
	}

	wantP := prefetch.Prefetch{
		Options: prefetch.Options{
			SourcePath:      "A",
			DestinationPath: "A",
		},
		Strategy: "A",
		Count:    50,
		DiskSize: 51,
	}
	if p := s.Select(prefetch.Options{}, wantAv, nil); !reflect.DeepEqual(p, wantP) {
		t.Fatalf("want prefetch = %#v; got %#v", wantP, p)
	}
}

type dummy struct {
	available bool
	weight    int
	suffix    string
	err       error
}

func (d *dummy) Available() bool        { return d.available }
func (d *dummy) Weight() int            { return d.weight }
func (d *dummy) PostRun(_ string) error { return nil }
func (d *dummy) Scan(_ *index.Index) (suffix string, count, diskSize int64, err error) {
	return d.suffix, int64(d.weight), int64(d.weight) + 1, d.err
}
