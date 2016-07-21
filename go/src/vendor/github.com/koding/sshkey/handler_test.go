package sshkey

import (
	"encoding/json"
	"log"
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHandler tests the Handler function
func TestHandler(t *testing.T) {

	req, err := http.NewRequest("GET", "http://example.com/foo", nil)
	if err != nil {
		log.Fatal(err)
	}

	w := httptest.NewRecorder()
	Handler(w, req)

	if w.Code != 200 {
		t.Fatal("Status code is not 200")
	}

	if w.Body.String() == "" {
		t.Fatal("Body should not be empty")
	}

}

// TestHandlerDecode tests the Handler function can encode data or not
func TestHandlerDecode(t *testing.T) {

	req, err := http.NewRequest("GET", "http://example.com/foo", nil)
	if err != nil {
		log.Fatal(err)
	}

	w := httptest.NewRecorder()
	Handler(w, req)

	v := make(map[string]interface{})

	err = json.NewDecoder(w.Body).Decode(&v)
	if err != nil {
		t.Fatal("Decoding the body has a problem")
	}

}
