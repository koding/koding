package tigertonic

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"reflect"
	"strings"
	"testing"
)

func TestJSONLogger(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest(
		"POST",
		"http://example.com/foo?bar=baz",
		bytes.NewBufferString(`{"foo":"bar"}`),
	)
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")

	logger := JSONLogged(Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusOK, nil, &testResponse{"bar"}, nil
	}), nil)

	logger.RequestIDCreator = func(r *http.Request) RequestID {
		return "request-id"
	}

	b := &bytes.Buffer{}
	logger.Logger = log.New(b, "", 0)
	logger.ServeHTTP(w, r)

	var m jsonLog

	err := json.Unmarshal(b.Bytes()[6:], &m)
	if err != nil {
		t.Fatal(err)
	}

	expected := jsonLog{
		Message:   "POST /foo?bar=baz HTTP/1.1\nHTTP/1.1 200 OK",
		Type:      "http",
		RequestID: "request-id",
		Duration:  0,
		HTTP: jsonLogHTTP{
			Request: jsonLogHTTPRequest{
				Body: "{\"foo\":\"bar\"}",
				Header: map[string]string{
					"accept":       "application/json",
					"content-type": "application/json",
				},
				Method: "POST",
				Path:   "/foo?bar=baz",
			},
			Response: jsonLogHTTPResponse{
				Body: "{\"foo\":\"bar\"}\n",
				Header: map[string]string{
					"content-type": "application/json",
				},
				StatusCode: 200,
				StatusText: "OK",
			},
			Version: "1.1",
		},
	}

	if reflect.DeepEqual(expected, m) == false {
		t.Fatalf("Log object was incorrect\nExpected\n%+v\nGot\n%+v", expected, m)
	}
}

func TestJSONLoggerRedactor(t *testing.T) {
	w := &testResponseWriter{}

	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")

	logger := JSONLogged(Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusOK, nil, &testResponse{"SECRET"}, nil
	}), func(s string) string {
		return strings.Replace(s, "SECRET", "REDACTED", -1)
	})

	b := &bytes.Buffer{}
	logger.Logger = log.New(b, "", 0)
	logger.ServeHTTP(w, r)
	s := b.String()

	if strings.Contains(s, "SECRET") {
		t.Fatal(s)
	}

	if !strings.Contains(s, "REDACTED") {
		t.Fatal(s)
	}
}
