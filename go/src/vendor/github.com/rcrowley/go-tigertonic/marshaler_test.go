package tigertonic

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"testing"
)

func TestMarshaledCalm(t *testing.T) {
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return 0, http.Header{}, nil, nil
	})
}

func TestMarshaledCalmStreamResponse(t *testing.T) {
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, io.Reader, error) {
		return 0, http.Header{}, nil, nil
	})
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, io.ReadCloser, error) {
		return 0, http.Header{}, nil, nil
	})
}

func TestMarshaledPanicNumIn(t *testing.T) {
	testMarshaledPanic(func() {}, t)
	testMarshaledPanic(func(u interface{}) {}, t)
	testMarshaledPanic(func(u, h interface{}) {}, t)
	testMarshaledPanic(func(u, h, rq, foo, bar interface{}) {}, t)
}

func TestMarshaledPanicIn0(t *testing.T) {
	testMarshaledPanic(func(u, h, rq interface{}) {}, t)
}

func TestMarshaledPanicIn1(t *testing.T) {
	testMarshaledPanic(func(u *url.URL, h, rq interface{}) {}, t)
}

func TestMarshaledPanicNumOut(t *testing.T) {
	testMarshaledPanic(func(u *url.URL, h http.Header) {}, t)
	testMarshaledPanic(func(u *url.URL, h http.Header) int {
		return 0
	}, t)
	testMarshaledPanic(func(u *url.URL, h http.Header) (int, int) {
		return 0, 0
	}, t)
	testMarshaledPanic(func(u *url.URL, h http.Header) (int, int, int) {
		return 0, 0, 0
	}, t)
	testMarshaledPanic(func(u *url.URL, h http.Header) (int, int, int, int, int) {
		return 0, 0, 0, 0, 0
	}, t)
}

func TestMarshaledPanicOut0(t *testing.T) {
	testMarshaledPanic(func(u *url.URL, h http.Header, rq *testRequest) (string, int, int, int) {
		return "", 0, 0, 0
	}, t)
}

func TestMarshaledPanicOut1(t *testing.T) {
	testMarshaledPanic(func(u *url.URL, h http.Header, rq *testRequest) (int, int, int, int) {
		return 0, 0, 0, 0
	}, t)
}

func TestMarshaledPanicOut2(t *testing.T) {
	testMarshaledPanic(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, int, int) {
		return 0, http.Header{}, 0, 0
	}, t)
}

func TestMarshaledPanicOut3(t *testing.T) {
	testMarshaledPanic(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, int) {
		return 0, http.Header{}, nil, 0
	}, t)
}

func TestNotAcceptable(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "text/plain")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusNoContent, nil, nil, nil
	}).ServeHTTP(w, r)
	if http.StatusNotAcceptable != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestUnsupportedMediaType(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusNoContent, nil, nil, nil
	}).ServeHTTP(w, r)
	if http.StatusUnsupportedMediaType != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestBadRequest(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString(""))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusNoContent, nil, nil, nil
	}).ServeHTTP(w, r)
	if http.StatusBadRequest != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "{\"description\":\"EOF\",\"error\":\"error\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestBadRequestSyntaxError(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("}"))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusNoContent, nil, nil, nil
	}).ServeHTTP(w, r)
	if http.StatusBadRequest != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "{\"description\":\"invalid character '}' looking for beginning of value\",\"error\":\"json.SyntaxError\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestInternalServerError(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")
	Marshaled(func(u *url.URL, h http.Header) (int, http.Header, *testResponse, error) {
		return 0, nil, nil, errors.New("foo")
	}).ServeHTTP(w, r)
	if http.StatusInternalServerError != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "{\"description\":\"foo\",\"error\":\"error\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestHTTPEquivError(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")
	Marshaled(func(u *url.URL, h http.Header) (int, http.Header, *testResponse, error) {
		return 0, nil, nil, ServiceUnavailable{errors.New("foo")}
	}).ServeHTTP(w, r)
	if http.StatusServiceUnavailable != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "{\"description\":\"foo\",\"error\":\"tigertonic.ServiceUnavailable\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestSnakeCaseHTTPEquivError(t *testing.T) {
	SnakeCaseHTTPEquivErrors = true
	defer func() { SnakeCaseHTTPEquivErrors = false }()
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")
	Marshaled(func(u *url.URL, h http.Header) (int, http.Header, *testResponse, error) {
		return 0, nil, nil, ServiceUnavailable{errors.New("foo")}
	}).ServeHTTP(w, r)
	if http.StatusServiceUnavailable != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "{\"description\":\"foo\",\"error\":\"service_unavailable\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestNamedError(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")
	Marshaled(func(u *url.URL, h http.Header) (int, http.Header, *testResponse, error) {
		return 0, nil, nil, testNamedError("foo")
	}).ServeHTTP(w, r)
	if http.StatusInternalServerError != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "{\"description\":\"foo\",\"error\":\"foo\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestNoContent(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusNoContent, nil, nil, nil
	}).ServeHTTP(w, r)
	if http.StatusNoContent != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestNilContent(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusOK, nil, nil, nil
	}).ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestHeader(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	r.Header.Set("Accept", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		return http.StatusNoContent, map[string][]string{
			"Foo": {"bar"},
		}, nil, nil
	}).ServeHTTP(w, r)
	if "bar" != w.Header().Get("Foo") {
		t.Fatal(w.Header().Get("Foo"))
	}
}

func TestBody(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{\"foo\":\"bar\"}"))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testResponse, error) {
		if "bar" != rq.Foo {
			t.Fatal(rq.Foo)
		}
		return http.StatusOK, nil, &testResponse{"bar"}, nil
	}).ServeHTTP(w, r)
	if "{\"foo\":\"bar\"}\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestEmptyBody(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	Marshaled(func(*url.URL, http.Header, interface{}) (int, http.Header, interface{}, error) {
		return http.StatusOK, nil, nil, nil
	}).ServeHTTP(w, r)
	if "" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestMarshaledShortGET(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	Marshaled(func(*url.URL, http.Header) (int, http.Header, interface{}, error) {
		return http.StatusOK, nil, nil, nil
	}).ServeHTTP(w, r)
	if "" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func Test500OnMisconfiguredPost(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("anything"))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header) (int, http.Header, *testResponse, error) {
		return http.StatusOK, nil, &testResponse{"bar"}, nil
	}).ServeHTTP(w, r)
	if http.StatusInternalServerError != w.StatusCode {
		t.Fatalf("Server did not 500 when trying to handle a POST to a handler with interface{} as the request type")
	}
}

func TestNonPointerMapBody(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString(`{"a": "b"}`))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Logged(Marshaled(func(u *url.URL, h http.Header, m map[string]string) (int, http.Header, string, error) {
		return http.StatusOK, nil, m["a"], nil
	}), nil).ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatalf("Server responded %d to a post with a non-pointer map body", w.StatusCode)
	}
	var result string
	_ = json.Unmarshal(w.Body.Bytes(), &result)
	if "b" != result {
		t.Fatalf("Body should have been 'b', but instead was '%s'", string(w.Body.Bytes()))
	}
}

func TestNonPointerSliceBody(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString(`["a", "b", "c"]`))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	Logged(Marshaled(func(u *url.URL, h http.Header, s []string) (int, http.Header, string, error) {
		return http.StatusOK, nil, s[1], nil
	}), nil).ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatalf("Server responded %d to a post with a non-pointer map body", w.StatusCode)
	}
	var result string
	_ = json.Unmarshal(w.Body.Bytes(), &result)
	if "b" != result {
		t.Fatalf("Body should have been 'b', but instead was '%s'", string(w.Body.Bytes()))
	}
}

func TestStreamResponse(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{\"foo\":\"bar\"}"))
	r.Header.Set("Accept", "image/*") // accept non-JSON response
	r.Header.Set("Content-Type", "application/json")
	reader := &testReader{Buffer: bytes.NewBufferString("teststream")}
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, io.ReadCloser, error) {
		if "bar" != rq.Foo {
			t.Fatal(rq.Foo)
		}
		headers := make(http.Header)
		headers.Set("Content-Type", "image/jpeg")
		return http.StatusOK, headers, reader, nil
	}).ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatalf("Server responded %d to a request with a stream response", w.StatusCode)
	}
	if "teststream" != w.Body.String() {
		t.Errorf("Body should have been 'teststream', but instead was '%s'", w.Body.String())
	}
	if x := w.Header().Get("Content-Type"); "image/jpeg" != x {
		t.Errorf("Content type should have been 'image/jpeg', but instead was '%s'", x)
	}
	if !reader.WasRead {
		t.Error("Stream should have been read")
	}
	if !reader.WasClosed {
		t.Error("Stream should have been closed")
	}
}

func TestStreamResponseWithNoContentType(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{\"foo\":\"bar\"}"))
	r.Header.Set("Accept", "image/*")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, io.Reader, error) {
		return http.StatusOK, nil, bytes.NewBufferString("teststream"), nil
	}).ServeHTTP(w, r)
	if http.StatusInternalServerError != w.StatusCode {
		t.Fatalf("Server responded %d to a request with a stream response but no 'Content-Type' header", w.StatusCode)
	}
}

func TestStreamResponseWithNotAcceptableContentType(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{\"foo\":\"bar\"}"))
	r.Header.Set("Accept", "image/jpeg")
	r.Header.Set("Content-Type", "application/json")
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, io.Reader, error) {
		headers := make(http.Header)
		headers.Set("Content-Type", "image/png")
		return http.StatusOK, headers, bytes.NewBufferString("teststream"), nil
	}).ServeHTTP(w, r)
	if http.StatusNotAcceptable != w.StatusCode {
		t.Fatalf("Server responded %d to a request with a stream response but without an acceptable 'Content-Type' header", w.StatusCode)
	}
}

// TestStreamResponseReader is trying to test the case where the return type of
// the Marshaled handler is a non-interface type that happens to implement the
// io.Reader interface.
// The expected behavior is that the response should NOT be read from the
// stream and if it implements io.Closer it should NOT close the stream and
// instead it should simply marshal the response to JSON.
func TestStreamResponseReader(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", bytes.NewBufferString("{\"foo\":\"bar\"}"))
	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	reader := &testReader{ID: "testreader", Buffer: bytes.NewBufferString("teststream")}
	Marshaled(func(u *url.URL, h http.Header, rq *testRequest) (int, http.Header, *testReader, error) {
		return http.StatusOK, nil, reader, nil
	}).ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatalf("Server responded %d to a post with a io.Reader implementing type", w.StatusCode)
	}
	if reader.WasRead {
		t.Error("Stream should not have been read")
	}
	if reader.WasClosed {
		t.Error("Stream should not have been closed")
	}
	data := new(testReader)
	if err := json.Unmarshal(w.Body.Bytes(), data); nil != err {
		t.Errorf("Could not unmarshal body %q: %s", err, w.Body.Bytes())
	} else if "testreader" != data.ID {
		t.Errorf("ID of response did not match")
	}
}

type testReader struct {
	ID        string `json:id`
	Buffer    *bytes.Buffer
	WasRead   bool
	WasClosed bool
}

func (c *testReader) Read(p []byte) (int, error) {
	c.WasRead = true
	return c.Buffer.Read(p)
}

func (c *testReader) Close() error {
	c.WasClosed = true
	return nil
}

func testMarshaledPanic(i interface{}, t *testing.T) {
	defer func() {
		err := recover()
		if nil == err {
			t.Fail()
		}
		if _, ok := err.(MarshalerError); !ok {
			t.Error(err)
		}
	}()
	Marshaled(i)
}

type testNamedError string

func (err testNamedError) Error() string { return string(err) }

func (err testNamedError) Name() string { return string(err) }

type testRequest struct {
	Foo string `json:"foo"`
}

type testResponse struct {
	Foo string `json:"foo"`
}
