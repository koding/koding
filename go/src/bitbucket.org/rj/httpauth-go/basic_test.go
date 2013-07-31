// Copyright 2012 Robert W. Johnstone. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package httpauth

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"testing"
	"time"
)

var (
	basicAuth *Basic
)

const (
	port string = ":8088"
)

func init() {
	basicAuth = NewBasic("golang", func(username, password string) bool {
		return username == password
	}, nil)

	http.HandleFunc("/basic/", basicHandler)
	go http.ListenAndServe(port, nil)
	time.Sleep(1 * time.Second)
}

func basicHandler(w http.ResponseWriter, r *http.Request) {
	username := basicAuth.Authorize(r)
	if username == "" {
		basicAuth.NotifyAuthRequired(w, r)
		return
	}

	fmt.Fprintf(w, "<html><body><h1>Hello</h1><p>Welcome, %s</p></body></html>", username)
}

func TestBasicNoAuth(t *testing.T) {
	resp, err := http.Get("http://localhost" + port + "/basic/")
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

func TestBasicBadAuth(t *testing.T) {
	resp, err := http.Get("http://user:pass@localhost" + port + "/basic/")
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

func TestBasicGoodAuth(t *testing.T) {
	resp, err := http.Get("http://user:user@localhost" + port + "/basic/")
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

}

func TestBasicCredientials(t *testing.T) {
	resp, err := http.Get("http://user:pass@localhost" + port + "/basic/")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	defer resp.Body.Close()

	token := resp.Request.Header.Get("Authorization")
	username, password := basicAuth.ParseToken(token)
	if username != "user" || password != "pass" {
		t.Errorf("auth.Credentials returned incorrect values.")
	}
}
