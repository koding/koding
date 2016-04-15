package udnssdk

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"testing"
	"time"
)

var (
	testUsername    = os.Getenv("ULTRADNS_USERNAME")
	testPassword    = os.Getenv("ULTRADNS_PASSWORD")
	testDomain      = os.Getenv("ULTRADNS_DOMAIN")
	testHostname    = os.Getenv("ULTRADNS_TEST_HOSTNAME")
	testIP1         = os.Getenv("ULTRADNS_TEST_IP1")
	testIP2         = os.Getenv("ULTRADNS_TEST_IP2")
	testBaseURL     = os.Getenv("ULTRADNS_BASEURL")
	testQuery       = os.Getenv("ULTRADNS_TEST_QUERY")
	testProbeType   = os.Getenv("ULTRADNS_TEST_PROBE_TYPE")
	testProbeName   = os.Getenv("ULTRADNS_TEST_PROBE_NAME")
	testProbeDomain = os.Getenv("ULTRADNS_TEST_PROBE_DOMAIN")

	testIPDPoolName    = "testipdpool"
	testIPDPoolAddress = "127.0.0.1"
	testIPDPoolDescr   = "A Test IP Directional Pool Group"
	testIPAddrDTO      = IPAddrDTO{Address: "127.0.0.1"}
	testIPDPool        = AccountLevelIPDirectionalGroupDTO{Name: "testippool", Description: "An IP Test Pool", IPs: []IPAddrDTO{IPAddrDTO{Address: "127.0.0.1"}}}
	testGeoDPool       = AccountLevelGeoDirectionalGroupDTO{Name: "testgeopool", Description: "A test geo pool", Codes: []string{"US, UK"}}
	testGeoDPoolName   = "testgeodpool"
	testGeoDPoolDescr  = "A Test Geo Directional Pool Group"
	testGeoDPoolCodes  = []string{"US", "UK"}

	envenableAccountTests         = os.Getenv("ULTRADNS_ENABLE_ACCOUNT_TESTS")
	envenableRRSetTests           = os.Getenv("ULTRADNS_ENABLE_RRSET_TESTS")
	envenableProbeTests           = os.Getenv("ULTRADNS_ENABLE_PROBE_TESTS")
	envenableChanges              = os.Getenv("ULTRADNS_ENABLE_CHANGES")
	envenableDirectionalPoolTests = os.Getenv("ULTRADNS_ENABLE_DPOOL_TESTS")
	envEnableIntegrationTests     = os.Getenv("ULTRADNS_ENABLE_INTEGRATION_TESTS")
	enableAccountTests            = true
	enableRRSetTests              = true
	enableProbeTests              = true
	enableChanges                 = true
	enableDirectionalPoolTests    = false
	enableIntegrationTests        = false
	testProfile                   = `{"@context": "http://schemas.ultradns.com/RDPool.jsonschema", "order": "ROUND_ROBIN","description": "T. migratorius"}`
	testProfile2                  = `{"@context": "http://schemas.ultradns.com/RDPool.jsonschema", "order": "RANDOM","description": "T. migratorius"}`

	testClient   *Client
	testAccounts []Account
)

func TestMain(m *testing.M) {
	rand.Seed(time.Now().UnixNano())

	if envEnableIntegrationTests == "false" || envEnableIntegrationTests == "0" {
		enableIntegrationTests = false
	} else if envEnableIntegrationTests == "true" || envEnableIntegrationTests == "1" {
		enableIntegrationTests = true
	}

	if enableIntegrationTests {
		if testUsername == "" {
			log.Printf("Please configure ULTRADNS_USERNAME.\n")
			os.Exit(1)
		}
		if testPassword == "" {
			log.Printf("Please configure ULTRADNS_PASSWORD.\n")
			os.Exit(1)
		}
		if testDomain == "" {
			log.Printf("Please configure ULTRADNS_DOMAIN.\n")
			os.Exit(1)
		}
		if testHostname == "" {
			log.Printf("Please configure ULTRADNS_TEST_HOSTNAME.\n")
			os.Exit(1)
		}
	}

	if testBaseURL == "" {
		testBaseURL = DefaultTestBaseURL
	}

	if testIP1 == "" {
		testIP1 = "54.86.13.225"
	}
	if testIP2 == "" {
		testIP2 = fmt.Sprintf("54.86.13.%d", (rand.Intn(254) + 1))
	}
	if testQuery == "" {
		testQuery = "nexus"
	}

	if testProbeName == "" || testProbeType == "" {
		testProbeName = "nexus2"
		testProbeType = "A"
	}
	if testProbeDomain == "" {
		testProbeDomain = testDomain
	}

	if envenableAccountTests == "false" || envenableAccountTests == "0" {
		enableAccountTests = false
	} else if envenableAccountTests == "true" || envenableAccountTests == "1" {
		enableAccountTests = true
	}

	if envenableRRSetTests == "false" || envenableRRSetTests == "0" {
		enableRRSetTests = false
	} else if envenableRRSetTests == "true" || envenableRRSetTests == "1" {
		enableRRSetTests = true
	}
	// TODO: I need a better way of handling this.
	/*
		if envenableFUDGETests == "false" || envenableFUDGETests == "0" {
			enableFUDGETests = false
		} else if envenableFUDGETests == "true" || envenableFUDGETests == "1" {
			enableFUDGETests = true
		}
	*/

	if envenableProbeTests == "false" || envenableProbeTests == "0" {
		enableProbeTests = false
	} else if envenableProbeTests == "true" || envenableProbeTests == "1" {
		enableProbeTests = true
	}

	if envenableChanges == "false" || envenableChanges == "0" {
		enableChanges = false
	} else if envenableChanges == "true" || envenableChanges == "1" {
		enableChanges = true
	}

	if envenableDirectionalPoolTests == "false" || envenableDirectionalPoolTests == "0" {
		enableDirectionalPoolTests = false
	} else if envenableDirectionalPoolTests == "true" || envenableDirectionalPoolTests == "1" {
		enableDirectionalPoolTests = true
	}

	testAccounts = nil
	os.Exit(m.Run())
}

func Test_CreateClient(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}

	log.Printf("Creating Client...\n")
	var err error
	testClient, err = NewClient(testUsername, testPassword, testBaseURL)

	if testClient == nil || err != nil {
		t.Fail()
		log.Fatalf("Could not create client - %+v\n", err)
		os.Exit(1)
	}
	t.Logf("Client created successfully.\n")
}
