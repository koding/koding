// Copyright 2012 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package httpauth

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"testing"
)

var (
	digestAuth *Digest
	success    chan bool
)

func init() {
	var err error
	digestAuth, err = NewDigest("golang", func(username string) string {
		return username
	}, nil)
	if err != nil {
		panic(err)
	}

	success = make(chan bool)

	http.HandleFunc("/digest/", digestHandler)
}

func digestHandler(w http.ResponseWriter, r *http.Request) {
	username := digestAuth.Authorize(r)
	if username == "" {
		digestAuth.NotifyAuthRequired(w, r)
		return
	}

	fmt.Fprintf(w, "<html><body><h1>Hello</h1><p>Welcome, %s</p></body></html>", username)
	success <- true
}

func TestDigestNoAuth(t *testing.T) {
	resp, err := http.Get("http://localhost" + port + "/digest/")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("Received incorrect status: %d", resp.StatusCode)
	}

	buffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	if string(buffer) != StatusUnauthorizedHtml {
		println(string(buffer))
		t.Errorf("Incorrect body text.")
	}

}

func TestDigestBadAuth(t *testing.T) {
	resp, err := http.Get("http://user:pass@localhost" + port + "/digest/")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("Received incorrect status: %d", resp.StatusCode)
	}

	buffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	if string(buffer) != StatusUnauthorizedHtml {
		println(string(buffer))
		t.Errorf("Incorrect body text.")
	}

}

/*func TestDigestGoodAuth(t *testing.T) {
	resp, err := http.Get("http://user:user@localhost" + port + "/digest/")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Received incorrect status: %d", resp.StatusCode)
	}

	buffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	if string(buffer) != "<html><body><h1>Hello</h1><p>Welcome, user</p></body></html>" {
		println(string(buffer))
		t.Errorf("Incorrect body text.")
	}

}*/

func TestDigestBrowser(t *testing.T) {
	url := "http://user:user@localhost" + port + "/digest/"
	fmt.Println( "Use a webbrowser, and navigate to", url, "to check digest authentication." )
	fmt.Println( "For authentication to succeed, the username and password must match." )
	<-success
}

func TestDigestBrowser2(t *testing.T) {
	url := "http://user:user@localhost" + port + "/digest/"
	fmt.Println( "Use a webbrowser, and navigate to", url, "to check digest authentication." )
	fmt.Println( "For authentication to succeed, the username and password must match." )
	<-success
	url = url + "sub/"
	fmt.Println( "Now try", url, "to check digest authentication." )
	<-success
}
