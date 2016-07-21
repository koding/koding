package maxminddb_test

import (
	"fmt"
	"log"
	"net"

	"github.com/oschwald/maxminddb-golang"
)

// This example shows how to decode to a struct
func ExampleReader_Lookup_struct() {
	db, err := maxminddb.Open("test-data/test-data/GeoIP2-City-Test.mmdb")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	ip := net.ParseIP("81.2.69.142")

	var record struct {
		Country struct {
			ISOCode string `maxminddb:"iso_code"`
		} `maxminddb:"country"`
	} // Or any appropriate struct

	err = db.Lookup(ip, &record)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Print(record.Country.ISOCode)
	// Output:
	// GB
}

// This example demonstrates how to decode to an interface{}
func ExampleReader_Lookup_interface() {
	db, err := maxminddb.Open("test-data/test-data/GeoIP2-City-Test.mmdb")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	ip := net.ParseIP("81.2.69.142")

	var record interface{}
	err = db.Lookup(ip, &record)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("%v", record)
}

// This example demonstrates how to iterate over all networks in the
// database
func ExampleReader_Networks() {
	db, err := maxminddb.Open("test-data/test-data/GeoIP2-Connection-Type-Test.mmdb")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	record := struct {
		Domain string `maxminddb:"connection_type"`
	}{}

	networks := db.Networks()
	for networks.Next() {
		subnet, err := networks.Network(&record)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Printf("%s: %s\n", subnet.String(), record.Domain)
	}
	if networks.Err() != nil {
		log.Fatal(networks.Err())
	}
	// Output:
	// ::100:0/120: Dialup
	// ::100:100/120: Cable/DSL
	// ::100:200/119: Dialup
	// ::100:400/118: Dialup
	// ::100:800/117: Dialup
	// ::100:1000/116: Dialup
	// ::100:2000/115: Dialup
	// ::100:4000/114: Dialup
	// ::100:8000/113: Dialup
	// ::50d6:0/116: Cellular
	// ::6001:0/112: Cable/DSL
	// ::600a:0/111: Cable/DSL
	// ::6045:0/112: Cable/DSL
	// ::605e:0/111: Cable/DSL
	// ::6c60:0/107: Cellular
	// ::af10:c700/120: Dialup
	// ::bb9c:8a00/120: Cable/DSL
	// ::c9f3:c800/120: Corporate
	// ::cfb3:3000/116: Cellular
	// 1.0.0.0/24: Dialup
	// 1.0.1.0/24: Cable/DSL
	// 1.0.2.0/23: Dialup
	// 1.0.4.0/22: Dialup
	// 1.0.8.0/21: Dialup
	// 1.0.16.0/20: Dialup
	// 1.0.32.0/19: Dialup
	// 1.0.64.0/18: Dialup
	// 1.0.128.0/17: Dialup
	// 80.214.0.0/20: Cellular
	// 96.1.0.0/16: Cable/DSL
	// 96.10.0.0/15: Cable/DSL
	// 96.69.0.0/16: Cable/DSL
	// 96.94.0.0/15: Cable/DSL
	// 108.96.0.0/11: Cellular
	// 175.16.199.0/24: Dialup
	// 187.156.138.0/24: Cable/DSL
	// 201.243.200.0/24: Corporate
	// 207.179.48.0/20: Cellular
	// 2001:0:100::/56: Dialup
	// 2001:0:100:100::/56: Cable/DSL
	// 2001:0:100:200::/55: Dialup
	// 2001:0:100:400::/54: Dialup
	// 2001:0:100:800::/53: Dialup
	// 2001:0:100:1000::/52: Dialup
	// 2001:0:100:2000::/51: Dialup
	// 2001:0:100:4000::/50: Dialup
	// 2001:0:100:8000::/49: Dialup
	// 2001:0:50d6::/52: Cellular
	// 2001:0:6001::/48: Cable/DSL
	// 2001:0:600a::/47: Cable/DSL
	// 2001:0:6045::/48: Cable/DSL
	// 2001:0:605e::/47: Cable/DSL
	// 2001:0:6c60::/43: Cellular
	// 2001:0:af10:c700::/56: Dialup
	// 2001:0:bb9c:8a00::/56: Cable/DSL
	// 2001:0:c9f3:c800::/56: Corporate
	// 2001:0:cfb3:3000::/52: Cellular
	// 2002:100::/40: Dialup
	// 2002:100:100::/40: Cable/DSL
	// 2002:100:200::/39: Dialup
	// 2002:100:400::/38: Dialup
	// 2002:100:800::/37: Dialup
	// 2002:100:1000::/36: Dialup
	// 2002:100:2000::/35: Dialup
	// 2002:100:4000::/34: Dialup
	// 2002:100:8000::/33: Dialup
	// 2002:50d6::/36: Cellular
	// 2002:6001::/32: Cable/DSL
	// 2002:600a::/31: Cable/DSL
	// 2002:6045::/32: Cable/DSL
	// 2002:605e::/31: Cable/DSL
	// 2002:6c60::/27: Cellular
	// 2002:af10:c700::/40: Dialup
	// 2002:bb9c:8a00::/40: Cable/DSL
	// 2002:c9f3:c800::/40: Corporate
	// 2002:cfb3:3000::/36: Cellular
	// 2003::/24: Cable/DSL

}
