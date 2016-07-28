package tigertonic

import (
	"bytes"
	"net/http"
)

type testResponseWriter struct {
	Body        bytes.Buffer
	StatusCode  int
	WroteHeader bool
	header      http.Header
}

func (w *testResponseWriter) Header() http.Header {
	if nil == w.header {
		w.header = make(map[string][]string)
	}
	return w.header
}

func (w *testResponseWriter) Write(p []byte) (int, error) {
	return w.Body.Write(p)
}

func (w *testResponseWriter) WriteHeader(code int) {
	w.StatusCode = code
	w.WroteHeader = true
}
