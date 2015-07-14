package info

import (
	"io/ioutil"
	"path/filepath"
	"regexp"
	"testing"
	"time"

	//"github.com/domainr/whois"
)

// WhoisQuery has very basic behavior currently - so we're just
// running a couple simple query tests.
func TestWhoisQuery(t *testing.T) {
	res, err := WhoisQuery("koding.com", "whois.arin.net", 1*time.Second)
	if err != nil {
		t.Fatal(err)
	}

	if res == "" {
		t.Error("Whois response empty.")
	}

	// Use a the street name to validate the response
	if regexp.MustCompile(`(?i)brannan`).MatchString(res) != true {
		t.Error("Response does not match as expected." +
			`Wanted the regexp "brannan" to match`)
	}
}

func TestCheckDigitalOcean(t *testing.T) {
	// Load our DO test Whois data(s) from fs
	b, err := ioutil.ReadFile(filepath.Join("testdata", "whois-do-1.txt"))
	if err != nil {
		t.Fatal(err)
	}
	whois := string(b)

	isDo, err := checkDigitalOcean(whois)
	if err != nil {
		t.Error(err)
	}

	if !isDo {
		t.Error("Expected checkDigitalOcean to match testdata/whois-do-1.txt")
	}

	b, err = ioutil.ReadFile(filepath.Join("testdata", "whois-koding.com.txt"))
	if err != nil {
		t.Fatal(err)
	}
	whois = string(b)

	isDo, err = checkDigitalOcean(whois)
	if err != nil {
		t.Error(err)
	}

	if isDo {
		t.Error("Expected checkDigitalOcean not to match testdata/whois-koding.com.txt")
	}

}
