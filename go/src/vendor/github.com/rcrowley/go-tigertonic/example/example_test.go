package main

import (
	"github.com/rcrowley/go-tigertonic/mocking"
	"net/http"
	"testing"
)

func TestCreate(t *testing.T) {
	code, header, response, err := create(
		mocking.URL(hMux, "POST", "http://example.com/1.0/stuff"),
		mocking.Header(nil),
		&MyRequest{"ID", "STUFF"},
	)
	if nil != err {
		t.Fatal(err)
	}
	if http.StatusCreated != code {
		t.Fatal(code)
	}
	if "http://example.com/1.0/stuff/ID" != header.Get("Content-Location") {
		t.Fatal(header)
	}
	if "ID" != response.ID || "STUFF" != response.Stuff {
		t.Fatal(response)
	}
}

func TestGet(t *testing.T) {
	code, _, response, err := get(
		mocking.URL(hMux, "GET", "http://example.com/1.0/stuff/ID"),
		mocking.Header(nil),
		nil,
	)
	if nil != err {
		t.Fatal(err)
	}
	if http.StatusOK != code {
		t.Fatal(code)
	}
	if "ID" != response.ID || "STUFF" != response.Stuff {
		t.Fatal(response)
	}
}

func TestMethodNotAllowed(t *testing.T) {
	defer func() { recover() }()
	mocking.URL(hMux, "PUT", "http://example.com/1.0/stuff")
	t.Fail()
}

func TestNotFound(t *testing.T) {
	defer func() { recover() }()
	mocking.URL(hMux, "GET", "http://example.com/1.0/things")
	t.Fail()
}

func TestUpdate(t *testing.T) {
	code, _, response, err := update(
		mocking.URL(hMux, "POST", "http://example.com/1.0/stuff/ID"),
		mocking.Header(nil),
		&MyRequest{"ID", "STUFF"},
	)
	if nil != err {
		t.Fatal(err)
	}
	if http.StatusAccepted != code {
		t.Fatal(code)
	}
	if "ID" != response.ID || "STUFF" != response.Stuff {
		t.Fatal(response)
	}
}
