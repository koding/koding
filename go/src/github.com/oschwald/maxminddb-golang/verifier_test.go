package maxminddb

import "testing"

func TestVerifyOnGoodDatabases(t *testing.T) {
	databases := []string{
		"test-data/test-data/GeoIP2-Anonymous-IP-Test.mmdb",
		"test-data/test-data/GeoIP2-City-Test.mmdb",
		"test-data/test-data/GeoIP2-Connection-Type-Test.mmdb",
		"test-data/test-data/GeoIP2-Country-Test.mmdb",
		"test-data/test-data/GeoIP2-Domain-Test.mmdb",
		"test-data/test-data/GeoIP2-ISP-Test.mmdb",
		"test-data/test-data/GeoIP2-Precision-City-Test.mmdb",
		"test-data/test-data/MaxMind-DB-no-ipv4-search-tree.mmdb",
		"test-data/test-data/MaxMind-DB-string-value-entries.mmdb",
		"test-data/test-data/MaxMind-DB-test-decoder.mmdb",
		"test-data/test-data/MaxMind-DB-test-ipv4-24.mmdb",
		"test-data/test-data/MaxMind-DB-test-ipv4-28.mmdb",
		"test-data/test-data/MaxMind-DB-test-ipv4-32.mmdb",
		"test-data/test-data/MaxMind-DB-test-ipv6-24.mmdb",
		"test-data/test-data/MaxMind-DB-test-ipv6-28.mmdb",
		"test-data/test-data/MaxMind-DB-test-ipv6-32.mmdb",
		"test-data/test-data/MaxMind-DB-test-mixed-24.mmdb",
		"test-data/test-data/MaxMind-DB-test-mixed-28.mmdb",
		"test-data/test-data/MaxMind-DB-test-mixed-32.mmdb",
		"test-data/test-data/MaxMind-DB-test-nested.mmdb",
	}

	for _, database := range databases {
		reader, err := Open(database)
		if err != nil {
			t.Error(err)
		}
		if err = reader.Verify(); err != nil {
			t.Errorf("Received error (%v) when verifying %v", err, database)
		}
	}
}

func TestVerifyOnBrokenDatabases(t *testing.T) {
	databases := []string{
		"test-data/test-data/GeoIP2-City-Test-Broken-Double-Format.mmdb",
		"test-data/test-data/MaxMind-DB-test-broken-pointers-24.mmdb",
		"test-data/test-data/MaxMind-DB-test-broken-search-tree-24.mmdb",
	}

	for _, database := range databases {
		reader, err := Open(database)
		if err != nil {
			t.Error(err)
		}
		err = reader.Verify()
		if err == nil {
			t.Errorf(
				"Did not receive expected error when verifying %v",
				database,
			)
		}
	}
}
