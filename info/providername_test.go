package info

import (
	"fmt"
	"net/http"
	"net/http/httptest"
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
	ts := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			//r.URL.Path
			//w.WriteHeader(http.StatusNotFound)
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
