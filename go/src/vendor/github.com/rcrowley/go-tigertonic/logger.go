package tigertonic

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

// ApacheLogger is an http.Handler that logs requests and responses in the
// Apache combined log format.
type ApacheLogger struct {
	Logger  Logger
	handler http.Handler
}

// ApacheLogged returns an http.Handler that logs requests and responses in
// the Apache combined log format.
func ApacheLogged(handler http.Handler) *ApacheLogger {
	return &ApacheLogger{
		Logger:  log.New(os.Stdout, "", 0),
		handler: handler,
	}
}

func (l *ApacheLogger) Print(v ...interface{}) {
	l.Output(2, fmt.Sprint(v...))
}

func (l *ApacheLogger) Printf(format string, v ...interface{}) {
	l.Output(2, fmt.Sprintf(format, v...))
}

func (l *ApacheLogger) Output(calldepth int, s string) error {
	return l.Logger.Output(calldepth, s)
}

// ServeHTTP wraps the http.Request and http.ResponseWriter to log to standard
// output and pass through to the underlying http.Handler.
func (l *ApacheLogger) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	aw := &apacheLoggerResponseWriter{ResponseWriter: w}
	l.handler.ServeHTTP(aw, r)
	remoteAddr := r.RemoteAddr
	if index := strings.LastIndex(remoteAddr, ":"); index != -1 {
		remoteAddr = remoteAddr[:index]
	}
	referer := r.Referer()
	if "" == referer {
		referer = "-"
	}
	userAgent := r.UserAgent()
	if "" == userAgent {
		userAgent = "-"
	}
	username, _, _ := httpBasicAuth(r.Header)
	if "" == username {
		username = "-"
	}
	l.Printf(
		"%s %s %s [%v] \"%s %s %s\" %d %d \"%s\" \"%s\"",
		remoteAddr,
		"-", // We're not supporting identd, sorry.
		username,
		time.Now().Format("02/Jan/2006:15:04:05 -0700"),
		r.Method,
		r.RequestURI,
		r.Proto,
		aw.StatusCode,
		aw.Size,
		referer,
		userAgent,
	)
}

type Logger interface {
	Output(calldepth int, s string) error
	Print(v ...interface{})
	Printf(format string, v ...interface{})
	Println(v ...interface{})
}

// MultilineLogger is an http.Handler that logs requests and responses,
// complete with paths, statuses, headers, and bodies.  Sensitive information
// may be redacted by a user-defined function.
type MultilineLogger struct {
	Logger           Logger
	handler          http.Handler
	redactor         Redactor
	RequestIDCreator RequestIDCreator
}

// Logged returns an http.Handler that logs requests and responses, complete
// with paths, statuses, headers, and bodies.  Sensitive information may be
// redacted by a user-defined function.
func Logged(handler http.Handler, redactor Redactor) *MultilineLogger {
	return &MultilineLogger{
		Logger:           log.New(os.Stdout, "", log.Ltime|log.Lmicroseconds),
		handler:          handler,
		redactor:         redactor,
		RequestIDCreator: requestIDCreator,
	}
}

// Output overrides log.Logger's Output method, calling our redactor first.
func (l *MultilineLogger) Output(calldepth int, s string) error {
	if nil != l.redactor {
		s = l.redactor(s)
	}
	return l.Logger.Output(calldepth, s)
}

// Print is identical to log.Logger's Print but uses our overridden Output.
func (l *MultilineLogger) Print(v ...interface{}) {
	l.Output(2, fmt.Sprint(v...))
}

// Printf is identical to log.Logger's Print but uses our overridden Output.
func (l *MultilineLogger) Printf(format string, v ...interface{}) {
	l.Output(2, fmt.Sprintf(format, v...))
}

// Println is identical to log.Logger's Print but uses our overridden Output.
func (l *MultilineLogger) Println(v ...interface{}) {
	l.Output(2, fmt.Sprintln(v...))
}

// ServeHTTP wraps the http.Request and http.ResponseWriter to log to standard
// output and pass through to the underlying http.Handler.
func (l *MultilineLogger) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	requestID := l.RequestIDCreator(r)
	l.Printf(
		"%s > %s %s %s",
		requestID,
		r.Method,
		r.URL.RequestURI(),
		r.Proto,
	)
	for key, values := range r.Header {
		for _, value := range values {
			l.Printf("%s > %s: %s", requestID, key, value)
		}
	}
	l.Println(requestID, ">")
	r.Body = &multilineLoggerReadCloser{
		ReadCloser:      r.Body,
		MultilineLogger: l,
		requestID:       requestID,
	}
	l.handler.ServeHTTP(&multilineLoggerResponseWriter{
		ResponseWriter:  w,
		MultilineLogger: l,
		request:         r,
		requestID:       requestID,
	}, r)
}

// A Redactor is a function that takes and returns a string.  It is called
// to allow sensitive information to be redacted before it is logged.
type Redactor func(string) string

// A unique RequestID is given to each request and is included with each line
// of each log entry.
type RequestID string

// A RequestIDCreator is a function that takes a request and returns a unique
// RequestID for it.
type RequestIDCreator func(r *http.Request) RequestID

// Default RequestIDCreator implementation
func requestIDCreator(r *http.Request) RequestID {
	return NewRequestID()
}

// NewRequestID returns a new 16-character random RequestID.
func NewRequestID() RequestID {
	return RequestID(RandomBase62Bytes(16))
}

type apacheLoggerResponseWriter struct {
	http.Flusher
	http.ResponseWriter
	Size       int
	StatusCode int
}

func (w *apacheLoggerResponseWriter) Flush() {
	if f, ok := w.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

func (w *apacheLoggerResponseWriter) Write(p []byte) (int, error) {
	if w.StatusCode == 0 {
		w.WriteHeader(http.StatusOK)
	}
	size, err := w.ResponseWriter.Write(p)
	w.Size += size
	return size, err
}

func (w *apacheLoggerResponseWriter) WriteHeader(code int) {
	w.ResponseWriter.WriteHeader(code)
	w.StatusCode = code
}

type multilineLoggerReadCloser struct {
	io.ReadCloser
	*MultilineLogger
	requestID RequestID
}

func (r *multilineLoggerReadCloser) Read(p []byte) (int, error) {
	n, err := r.ReadCloser.Read(p)
	if 0 < n {
		r.Println(r.requestID, ">", string(p[:n]))
	}
	return n, err
}

type multilineLoggerResponseWriter struct {
	http.Flusher
	http.ResponseWriter
	*MultilineLogger
	request     *http.Request
	requestID   RequestID
	wroteHeader bool
}

func (w *multilineLoggerResponseWriter) Flush() {
	if f, ok := w.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

func (w *multilineLoggerResponseWriter) Write(p []byte) (int, error) {
	if !w.wroteHeader {
		w.WriteHeader(http.StatusOK)
	}
	if ct := w.Header().Get("Content-Type"); "" != ct && "application/json" != ct && "text/plain" != ct {
		w.Println(w.requestID, "<", "** response body redacted **")
	} else if len(p) > 0 && '\n' == p[len(p)-1] {
		w.Println(w.requestID, "<", string(p[:len(p)-1]))
	} else {
		w.Println(w.requestID, "<", string(p))
	}
	return w.ResponseWriter.Write(p)
}

func (w *multilineLoggerResponseWriter) WriteHeader(code int) {
	w.wroteHeader = true
	w.Printf(
		"%s < %s %d %s",
		w.requestID,
		w.request.Proto,
		code,
		http.StatusText(code),
	)
	for name, values := range w.Header() {
		for _, value := range values {
			w.Printf("%s < %s: %s", w.requestID, name, value)
		}
	}
	w.Println(w.requestID, "<")
	w.ResponseWriter.WriteHeader(code)
}
