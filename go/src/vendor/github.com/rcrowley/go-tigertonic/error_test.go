package tigertonic

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"testing"
)

var ttTestAcceptContentType = []struct {
	r           *http.Request
	contentType string
	out         bool
}{
	{&http.Request{Header: http.Header{"Accept": []string{"text/plain; q=0.3, */*"}}}, "image/jpeg", true},
	{&http.Request{Header: http.Header{"Accept": []string{"image/*; q=0.5, text/*"}}}, "text/plain", true},
	{&http.Request{Header: http.Header{"Accept": []string{"image/jpeg, text/*"}}}, "image/jpeg", true},
	{&http.Request{Header: http.Header{"Accept": []string{"image/*; q=0.5, text/*"}}}, "application/json", false},
}

func TestAcceptContentType(t *testing.T) {
	for i, tt := range ttTestAcceptContentType {
		if x := acceptContentType(tt.r, tt.contentType); x != tt.out {
			t.Errorf("Test %d expected %t", i, tt.out)
		}
	}
}

func TestNamedHTTPEquivError(t *testing.T) {
	var err error = OK{testNamedError("foo")}
	if "foo" != errorName(err, "error") {
		t.Fatal(errorName(err, "error"))
	}
}

func TestUnnamedError(t *testing.T) {
	var err error = errors.New("foo")
	if "error" != errorName(err, "error") {
		t.Fatal(errorName(err, "error"))
	}
}

func TestUnnamedHTTPEquivError(t *testing.T) {
	var err error = OK{errors.New("foo")}
	if "tigertonic.OK" != errorName(err, "error") {
		t.Fatal(errorName(err, "error"))
	}
}

func TestUnnamedSnakeCaseHTTPEquivError(t *testing.T) {
	SnakeCaseHTTPEquivErrors = true
	defer func() { SnakeCaseHTTPEquivErrors = false }()
	var err error = OK{errors.New("foo")}
	if "ok" != errorName(err, "error") {
		t.Fatal(errorName(err, "error"))
	}
}

func TestErrorWriter_DefaultWriter_StandardError(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{ }"))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusBadRequest, nil, nil, errors.New("TestError")
	}).ServeHTTP(w, r)
	if http.StatusBadRequest != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	//log.Printf("Return: %s", w.Body.String())
	if "{\"description\":\"TestError\",\"error\":\"error\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestErrorWriter_DefaultWriter_CustomError(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{ }"))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		testErr := TestError{Code: 1, Message: "This is a test"}
		return http.StatusBadRequest, nil, nil, testErr
	}).ServeHTTP(w, r)
	if http.StatusBadRequest != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	//log.Printf("Return: %s", w.Body.String())
	if "{\"description\":\"Code: [1] Message: [This is a test]\",\"error\":\"tigertonic.TestError\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestErrorWriter_TestWriter_StandardError(t *testing.T) {
	ResponseErrorWriter = TestErrorWriter{}

	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{ }"))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusBadRequest, nil, nil, errors.New("TestError")
	}).ServeHTTP(w, r)
	if http.StatusBadRequest != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	//log.Printf("Return: %s", w.Body.String())
	if "{\"description\":\"TestError\",\"error\":\"error\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}

	// Reset error writer after test...
	ResponseErrorWriter = defaultErrorWriter{}
}

func TestErrorWriter_TestWriter_CustomError(t *testing.T) {
	ResponseErrorWriter = TestErrorWriter{}

	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{ }"))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		testErr := TestError{Code: 1, Message: "This is a test"}
		return http.StatusBadRequest, nil, nil, testErr
	}).ServeHTTP(w, r)
	if http.StatusBadRequest != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	//log.Printf("Return: %s", w.Body.String())
	if "{\"Err\":{\"Code\":1,\"Message\":\"This is a test\"}}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}

	// Reset error writer after test...
	ResponseErrorWriter = defaultErrorWriter{}
}

// TestError is example error
type TestError struct {
	// Satisfy the generic error interface.
	error

	// Classification of error
	Code int

	// Detailed information about error
	Message string
}

// Error returns the string representation of the error.
func (e TestError) Error() string {
	return fmt.Sprintf("Code: [%v] Message: [%s]", e.Code, e.Message)
}

// String returns the string representation of the error.
func (e TestError) String() string {
	return e.Error()
}

type TestErrorWriter struct {
}

func (d TestErrorWriter) WriteError(r *http.Request, w http.ResponseWriter, err error) {
	if acceptJSON(r) {
		d.WriteJSONError(w, err)
	} else {
		d.WritePlaintextError(w, err)
	}
}

func (d TestErrorWriter) WriteJSONError(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(errorStatusCode(err))

	// Example of custom error formatting based on error type
	name := errorName(err, "error")
	if name == "tigertonic.TestError" {
		if jsonErr := json.NewEncoder(w).Encode(err); nil != jsonErr {
			log.Printf("Error marshalling error response into JSON output: %s", jsonErr)
		}
	} else {
		if jsonErr := json.NewEncoder(w).Encode(map[string]string{
			"description": err.Error(),
			"error":       errorName(err, "error"),
		}); nil != jsonErr {
			log.Printf("Error marshalling error response into JSON output: %s", jsonErr)
		}
	}
}

func (d TestErrorWriter) WritePlaintextError(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(errorStatusCode(err))
	fmt.Fprintf(w, "%s: %s", errorName(err, "error"), err)
}
