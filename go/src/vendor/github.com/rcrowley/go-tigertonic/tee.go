package tigertonic

import (
	"bytes"
	"net/http"
)

// TeeHeaderResponseWriter is an http.ResponseWriter that both writes and
// records the response status and headers for post-processing.
type TeeHeaderResponseWriter struct {
	http.Flusher
	http.ResponseWriter
	StatusCode int
}

// NewTeeHeaderResponseWriter constructs a new TeeHeaderResponseWriter that
// writes responses through another http.ResponseWriter and records the
// response status and headers for post-processing.
func NewTeeHeaderResponseWriter(w http.ResponseWriter) *TeeHeaderResponseWriter {
	return &TeeHeaderResponseWriter{ResponseWriter: w}
}

// Flush implements the http.Flusher interface, if possible, to support streaming
// responses to clients.
func (w *TeeHeaderResponseWriter) Flush() {
	if f, ok := w.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

// WriteHeader writes the response line and headers to the client via the
// underlying http.ResponseWriter and records the status for post-processing.
func (w *TeeHeaderResponseWriter) WriteHeader(code int) {
	w.ResponseWriter.WriteHeader(code)
	w.StatusCode = code
}

// TeeResponseWriter is an http.ResponseWriter that both writes and records the
// response status, headers, and body for post-processing.
type TeeResponseWriter struct {
	http.Flusher
	http.ResponseWriter
	Body       bytes.Buffer
	StatusCode int
}

// NewTeeResponseWriter constructs a new TeeResponseWriter that writes
// responses through another http.ResponseWriter and records the response
// status, headers, and body for post-processing.
func NewTeeResponseWriter(w http.ResponseWriter) *TeeResponseWriter {
	return &TeeResponseWriter{ResponseWriter: w}
}

// Flush implements the http.Flusher interface, if possible, to support streaming
// responses to clients.
func (w *TeeResponseWriter) Flush() {
	if f, ok := w.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

// Write writes the byte slice to the client via the underlying
// http.ResponseWriter and records it for post-processing.
func (w *TeeResponseWriter) Write(p []byte) (int, error) {
	if n, err := w.ResponseWriter.Write(p); nil != err {
		return n, err
	}
	return w.Body.Write(p)
}

// WriteHeader writes the response line and headers to the client via the
// underlying http.ResponseWriter and records the status for post-processing.
func (w *TeeResponseWriter) WriteHeader(code int) {
	w.ResponseWriter.WriteHeader(code)
	w.StatusCode = code
}
