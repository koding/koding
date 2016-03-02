package tigertonic

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

// JSONLogged is an http.Handler that logs requests and responses in a parse-able json line.
// complete with paths, statuses, headers, and bodies.  Sensitive information may be
// redacted by a user-defined function.
type JSONLogger struct {
	Logger           Logger
	handler          http.Handler
	redactor         Redactor
	RequestIDCreator RequestIDCreator
}

// JSONLogged returns an http.Handler that logs requests and responses in a parse-able json line.
// complete with paths, statuses, headers, and bodies.  Sensitive information may be
// redacted by a user-defined function.
func JSONLogged(handler http.Handler, redactor Redactor) *JSONLogger {
	return &JSONLogger{
		Logger:           log.New(os.Stdout, "", 0),
		handler:          handler,
		redactor:         redactor,
		RequestIDCreator: requestIDCreator,
	}
}

// ServeHTTP wraps the http.Request and http.ResponseWriter to capture the input and output for logging
func (jl *JSONLogger) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	t := time.Now()
	tee := NewTeeResponseWriter(w)
	rURI := r.URL.RequestURI()
	body := &jsonReadCloser{r.Body, bytes.Buffer{}}
	requestID := jl.RequestIDCreator(r)
	r.Body = body
	jl.handler.ServeHTTP(tee, r)
	buf, err := json.Marshal(&jsonLog{
		Duration: time.Since(t) / time.Millisecond,
		HTTP: jsonLogHTTP{
			Request: jsonLogHTTPRequest{
				Body:   body.Bytes.String(),
				Header: jsonLogHTTPHeader(r.Header),
				Method: r.Method,
				Path:   rURI,
			},
			Response: jsonLogHTTPResponse{
				Body:       tee.Body.String(),
				Header:     jsonLogHTTPHeader(tee.Header()),
				StatusCode: tee.StatusCode,
				StatusText: http.StatusText(tee.StatusCode),
			},
			Version: fmt.Sprintf("%d.%d", r.ProtoMajor, r.ProtoMinor),
		},
		Message: fmt.Sprintf(
			"%s %s %s\n%s %d %s",
			r.Method,
			rURI,
			r.Proto,
			r.Proto,
			tee.StatusCode,
			http.StatusText(tee.StatusCode),
		),
		RequestID: requestID,
		Type:      "http",
	})
	if err != nil {
		jl.Println(err.Error())
		return
	}
	jl.Println("@json:", string(buf))
}

func (jl *JSONLogger) Print(v ...interface{}) {
	jl.Output(2, fmt.Sprint(v...))
}

func (jl *JSONLogger) Printf(format string, v ...interface{}) {
	jl.Output(2, fmt.Sprintf(format, v...))
}

func (jl *JSONLogger) Println(v ...interface{}) {
	jl.Output(2, fmt.Sprintln(v...))
}

func (jl *JSONLogger) Output(calldepth int, s string) error {
	if nil != jl.redactor {
		s = jl.redactor(s)
	}

	return jl.Logger.Output(calldepth, s)
}

func jsonLogHTTPHeader(h http.Header) map[string]string {
	header := make(map[string]string)
	for name, values := range h {
		header[strings.ToLower(name)] = strings.Join(values, "; ")
	}
	return header
}

type jsonLog struct {
	Duration  time.Duration `json:"duration"`
	HTTP      jsonLogHTTP   `json:"http"`
	Message   string        `json:"@message"`
	RequestID RequestID     `json:"@request_id"`
	Type      string        `json:"@type"`
}

type jsonLogHTTP struct {
	Request  jsonLogHTTPRequest  `json:"request"`
	Response jsonLogHTTPResponse `json:"response"`
	Version  string              `json:"version"`
}

type jsonLogHTTPRequest struct {
	Body   string            `json:"body"`
	Header map[string]string `json:"headers"`
	Method string            `json:"method"`
	Path   string            `json:"url"`
}

type jsonLogHTTPResponse struct {
	Body       string            `json:"body"`
	Header     map[string]string `json:"headers"`
	StatusText string            `json:"reason"`
	StatusCode int               `json:"status"`
}

type jsonReadCloser struct {
	io.ReadCloser
	Bytes bytes.Buffer
}

func (r *jsonReadCloser) Read(p []byte) (int, error) {
	n, err := r.ReadCloser.Read(p)
	r.Bytes.Write(p[:n])
	return n, err
}
