package info

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"regexp"
	"testing"
	"time"
)

const testDir string = "testdata"

func loadTestData(t *testing.T, file string) string {
	// Get the full filepath
	file = filepath.Join(testDir, file)

	b, err := ioutil.ReadFile(file)
	if err != nil {
		t.Fatal(err)
	}

	return string(b)
}

// runRegexTest implements the repetative reading and testing of the
// ProviderChecker tests.
func runRegexCheckTest(t *testing.T, checker ProviderChecker,
	file string, expected bool) {

	// Use a test whois checker
	DefaultWhoisChecker = func() (string, error) {
		return loadTestData(t, file), nil
	}

	checkResult, err := checker()
	if err != nil {
		t.Error(err)
	}

	expectedStr := "match"
	if !expected {
		expectedStr = "not match"
	}

	if checkResult != expected {
		t.Error(fmt.Sprintf("Expected Checker to %s %s", expectedStr, file))
	}
}

// WhoisQuery has very basic behavior currently - so we're just
// running a couple simple query tests.
func TestWhoisQuery(t *testing.T) {
	// Retry WhoisQuery up to 3 times for network timeout errors.
	for i := 0; i < 3; i++ {
		res, err := WhoisQuery("koding.com", "whois.arin.net", 5*time.Second)
		if e, ok := err.(net.Error); ok && e.Timeout() {
			continue
		}

		if err != nil {
			t.Fatal(err)
		}

		if res == "" {
			t.Fatal("Whois response empty.")
		}

		// Use a the street name to validate the response
		if regexp.MustCompile(`(?i)brannan`).MatchString(res) != true {
			t.Fatal("Response does not match as expected." +
				`Wanted the regexp "brannan" to match`)
		}

		return
	}

	t.Fatal("exceeded max retry attempts for WhoisQuery")
}

func TestCheckDigitalOcean(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, "response")
		}))
	defer ts.Close()

	isDo, err := checkDigitalOcean(ts.URL)
	if err != nil {
		t.Error(err)
	}

	if !isDo {
		t.Error("Expected checkDigitalOcean to match on a StatusCode 200")
	}

	ts404 := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusNotFound)
			fmt.Fprint(w, "response")
		}))
	defer ts404.Close()

	isDo, err = checkDigitalOcean(ts404.URL)
	if err != nil {
		t.Error(err)
	}

	if isDo {
		t.Error("Expected checkDigitalOcean to NOT match on a StatusCode !200")
	}
}

func TestCheckAWS(t *testing.T) {
	runRegexCheckTest(t, CheckAWS,
		"whois-aws-vm-1.txt", true)

	runRegexCheckTest(t, CheckAWS,
		"whois-do-vm-1.txt", false)
}

func TestCheckAzure(t *testing.T) {
	runRegexCheckTest(t, CheckAzure,
		"whois-aws-vm-1.txt", false)

	runRegexCheckTest(t, CheckAzure,
		"whois-do-vm-1.txt", false)
}

func TestCheckGoogleCloud(t *testing.T) {
	runRegexCheckTest(t, CheckGoogleCloud,
		"whois-aws-vm-1.txt", false)

	runRegexCheckTest(t, CheckGoogleCloud,
		"whois-do-vm-1.txt", false)
}

func TestCheckHPCloud(t *testing.T) {
	runRegexCheckTest(t, CheckHPCloud,
		"whois-aws-vm-1.txt", false)

	runRegexCheckTest(t, CheckHPCloud,
		"whois-do-vm-1.txt", false)
}

func TestCheckJoyent(t *testing.T) {
	runRegexCheckTest(t, CheckJoyent,
		"whois-aws-vm-1.txt", false)

	runRegexCheckTest(t, CheckJoyent,
		"whois-do-vm-1.txt", false)
}

func TestCheckRackspace(t *testing.T) {
	runRegexCheckTest(t, CheckRackspace,
		"whois-aws-vm-1.txt", false)

	runRegexCheckTest(t, CheckRackspace,
		"whois-do-vm-1.txt", false)
}

func TestCheckSoftLayer(t *testing.T) {
	runRegexCheckTest(t, CheckSoftLayer,
		"whois-aws-vm-1.txt", false)

	runRegexCheckTest(t, CheckSoftLayer,
		"whois-do-vm-1.txt", false)
}

// checkProvider tests
func TestCheckProvider(t *testing.T) {
	providersToCheck := []ProviderName{
		AWS,
		Azure,
		GoogleCloud,
		Joyent,
		Rackspace,
		SoftLayer,

		// We can't check the DigitalOcean provider in this func,
		// because the func that implements ProviderChecker makes impure
		// http calls. This func is independently tested inside of
		// TestCheckDigitalOcean
		//DigitalOcean,
	}

	runProviderTest := func(file string, expectedProvider ProviderName) {
		// Use a test whois checker
		DefaultWhoisChecker = func() (string, error) {
			return loadTestData(t, file), nil
		}

		providerName, err := checkProvider(providersToCheck)
		if err != nil {
			t.Error(err)
		}
		if providerName != expectedProvider {
			t.Error(fmt.Sprintf(
				"Expected %s to match %s", file, expectedProvider))
		}
	}

	runProviderTest("whois-aws-vm-1.txt", AWS)
}
