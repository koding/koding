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
	cookieAuth *Cookie
)

const (
	htmlLogin string = `<html><head><title>Login</title></head><body><p>There should be a login form here</p></body></html>`
)

func init() {
	cookieAuth = NewCookie("golang", "http://localhost"+port+"/cookie/login/", func(username, password string) bool {
		return username == password
	})

	http.HandleFunc("/cookie/login/", cookieLoginHandler)
	http.HandleFunc("/cookie/", cookieHandler)
	go http.ListenAndServe(port, nil)
	time.Sleep(1 * time.Second)
}

func cookieHandler(w http.ResponseWriter, r *http.Request) {
	username := cookieAuth.Authorize(r)
	if username == "" {
		cookieAuth.NotifyAuthRequired(w, r)
		return
	}

	fmt.Fprintf(w, "<html><body><h1>Hello</h1><p>Welcome, %s</p></body></html>", username)
}

func cookieLoginHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, htmlLogin)
}

func TestCookieNoAuth(t *testing.T) {
	resp, err := http.Get("http://localhost" + port + "/cookie/")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Received incorrect status: %d", resp.StatusCode)
	}
	if resp.Request.URL.String() != "http://localhost"+port+"/cookie/login/" {
		t.Errorf("Received incorrect page: %s", resp.Request.URL.String())
	}

	buffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	if string(buffer) != htmlLogin {
		t.Errorf("Incorrect body text.")
	}

}

func TestCookieLogin(t *testing.T) {
	nonce1, err := cookieAuth.Login("user1", "user1")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	nonce2, err := cookieAuth.Login("user1", "user1")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	if nonce1 != nonce2 {
		t.Errorf("Error when login twice using the same username.")
	}
}

func TestCookieLogout(t *testing.T) {
	nonce, err := cookieAuth.Login("user1", "user1")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	cookieAuth.Logout(nonce)
}

func TestCookieGoodAuth(t *testing.T) {
	nonce, err := cookieAuth.Login("user1", "user1")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	req, err := http.NewRequest("GET", "http://localhost"+port+"/cookie/", nil)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	req.AddCookie(&http.Cookie{Name: "Authorization", Value: nonce})

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Received incorrect status: %d", resp.StatusCode)
	}
	if resp.Request.URL.String() != "http://localhost"+port+"/cookie/" {
		t.Errorf("Received incorrect page: %s", resp.Request.URL.String())
	}

	buffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	if string(buffer) != "<html><body><h1>Hello</h1><p>Welcome, user1</p></body></html>" {
		t.Errorf("Incorrect body text.")
	}

}

func TestCookieLogoutWeb(t *testing.T) {
	nonce, err := cookieAuth.Login("user1", "user1")
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	req, err := http.NewRequest("GET", "http://localhost"+port+"/cookie/", nil)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	req.AddCookie(&http.Cookie{Name: "Authorization", Value: nonce})

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Received incorrect status: %d", resp.StatusCode)
	}
	if resp.Request.URL.String() != "http://localhost"+port+"/cookie/" {
		t.Errorf("Received incorrect page: %s", resp.Request.URL.String())
	}

	buffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Error:  %s", err)
	}

	if string(buffer) != "<html><body><h1>Hello</h1><p>Welcome, user1</p></body></html>" {
		t.Errorf("Incorrect body text.")
	}

}
