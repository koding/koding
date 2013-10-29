// Copyright 2013 The Gorilla Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/*
Package handlers is a collection of handlers for use with Go's net/http package.
*/
package handlers

import (
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"
	"time"
)

// MethodHandler is an http.Handler that dispatches to a handler whose key in the MethodHandler's
// map matches the name of the HTTP request's method, eg: GET
//
// If the request's method is OPTIONS and OPTIONS is not a key in the map then the handler
// responds with a status of 200 and sets the Allow header to a comma-separated list of
// available methods.
//
// If the request's method doesn't match any of its keys the handler responds with
// a status of 406, Method not allowed and sets the Allow header to a comma-separated list
// of available methods.
type MethodHandler map[string]http.Handler

func (h MethodHandler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	if handler, ok := h[req.Method]; ok {
		handler.ServeHTTP(w, req)
	} else {
		allow := []string{}
		for k := range h {
			allow = append(allow, k)
		}
		sort.Strings(allow)
		w.Header().Set("Allow", strings.Join(allow, ", "))
		if req.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
		} else {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}
}

// loggingHandler is the http.Handler implementation for LoggingHandlerTo and its friends
type loggingHandler struct {
	writer  io.Writer
	handler http.Handler
}

// combinedLoggingHandler is the http.Handler implementation for LoggingHandlerTo and its friends
type combinedLoggingHandler struct {
	writer  io.Writer
	handler http.Handler
}

func (h loggingHandler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	t := time.Now()
	logger := responseLogger{w: w}
	h.handler.ServeHTTP(&logger, req)
	writeLog(h.writer, req, t, logger.status, logger.size)
}

func (h combinedLoggingHandler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	t := time.Now()
	logger := responseLogger{w: w}
	h.handler.ServeHTTP(&logger, req)
	writeCombinedLog(h.writer, req, t, logger.status, logger.size)
}

// responseLogger is wrapper of http.ResponseWriter that keeps track of its HTTP status
// code and body size
type responseLogger struct {
	w      http.ResponseWriter
	status int
	size   int
}

func (l *responseLogger) Header() http.Header {
	return l.w.Header()
}

func (l *responseLogger) Write(b []byte) (int, error) {
	if l.status == 0 {
		// The status will be StatusOK if WriteHeader has not been called yet
		l.status = http.StatusOK
	}
	size, err := l.w.Write(b)
	l.size += size
	return size, err
}

func (l *responseLogger) WriteHeader(s int) {
	l.w.WriteHeader(s)
	l.status = s
}

// buildCommonLogLine builds a log entry for req in Apache Common Log Format.
// ts is the timestamp with which the entry should be logged.
// status and size are used to provide the response HTTP status and size.
func buildCommonLogLine(req *http.Request, ts time.Time, status int, size int) string {
	username := "-"
	if req.URL.User != nil {
		if name := req.URL.User.Username(); name != "" {
			username = name
		}
	}

	return fmt.Sprintf("%s - %s [%s] \"%s %s %s\" %d %d",
		strings.Split(req.RemoteAddr, ":")[0],
		username,
		ts.Format("02/Jan/2006:15:04:05 -0700"),
		req.Method,
		req.URL.RequestURI(),
		req.Proto,
		status,
		size,
	)
}

// writeLog writes a log entry for req to w in Apache Common Log Format.
// ts is the timestamp with which the entry should be logged.
// status and size are used to provide the response HTTP status and size.
func writeLog(w io.Writer, req *http.Request, ts time.Time, status, size int) {
	line := buildCommonLogLine(req, ts, status, size) + "\n"
	fmt.Fprint(w, line)
}

// writeCombinedLog writes a log entry for req to w in Apache Combined Log Format.
// ts is the timestamp with which the entry should be logged.
// status and size are used to provide the response HTTP status and size.
func writeCombinedLog(w io.Writer, req *http.Request, ts time.Time, status, size int) {
	line := buildCommonLogLine(req, ts, status, size)
	combinedLine := fmt.Sprintf("%s \"%s\" \"%s\"\n", line, req.Referer(), req.UserAgent())
	fmt.Fprint(w, combinedLine)
}

// CombinedLoggingHandler return a http.Handler that wraps h and logs requests to out in
// Apache Combined Log Format.
//
// See http://httpd.apache.org/docs/2.2/logs.html#combined for a description of this format.
//
// LoggingHandler always sets the ident field of the log to -
func CombinedLoggingHandler(out io.Writer, h http.Handler) http.Handler {
	return combinedLoggingHandler{out, h}
}

// LoggingHandler return a http.Handler that wraps h and logs requests to out in
// Apache Common Log Format (CLF).
//
// See http://httpd.apache.org/docs/2.2/logs.html#common for a description of this format.
//
// LoggingHandler always sets the ident field of the log to -
func LoggingHandler(out io.Writer, h http.Handler) http.Handler {
	return loggingHandler{out, h}
}
