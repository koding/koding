package maxminddb

import (
	"fmt"
	"testing"
)

func TestNetworks(t *testing.T) {
	for _, recordSize := range []uint{24, 28, 32} {
		for _, ipVersion := range []uint{4, 6} {
			fileName := fmt.Sprintf("test-data/test-data/MaxMind-DB-test-ipv%d-%d.mmdb", ipVersion, recordSize)
			reader, err := Open(fileName)
			if err != nil {
				t.Fatalf("unexpected error while opening database: %v", err)
			}
			defer reader.Close()

			n := reader.Networks()
			for n.Next() {
				record := struct {
					IP string `maxminddb:"ip"`
				}{}
				network, err := n.Network(&record)
				if err != nil {
					t.Fatal(err)
				}

				if record.IP != network.IP.String() {
					t.Fatalf("expected %s got %s", record.IP, network.IP.String())
				}
			}
			if n.Err() != nil {
				t.Fatal(n.Err())
			}
		}
	}
}

func TestNetworksWithInvalidSearchTree(t *testing.T) {
	reader, err := Open("test-data/test-data/MaxMind-DB-test-broken-search-tree-24.mmdb")
	if err != nil {
		t.Fatalf("unexpected error while opening database: %v", err)
	}
	defer reader.Close()

	n := reader.Networks()
	for n.Next() {
		var record interface{}
		_, err := n.Network(&record)
		if err != nil {
			t.Fatal(err)
		}
	}
	if n.Err() == nil {
		t.Fatal("no error received when traversing an broken search tree")
	} else if n.Err().Error() != "invalid search tree at 128.128.128.128/32" {
		t.Error(n.Err())
	}
}
