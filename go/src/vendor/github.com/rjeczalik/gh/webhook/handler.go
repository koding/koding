package webhook

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"reflect"
	"strings"

	"golang.org/x/net/context"
)

const maxPayloadLen = 1024 * 1024 // 1MiB

var (
	errMethod      = errors.New("invalid HTTP method")
	errHeaders     = errors.New("invalid HTTP headers")
	errSig         = errors.New("invalid signature header")
	errSigKind     = errors.New("unsupported signature hash type")
	errPayload     = errors.New("unsupported payload type")
	errContentType = errors.New("unsupported content type")
)

var empty = reflect.TypeOf(func(interface{}) {}).In(0)
var contextType = reflect.TypeOf((*context.Context)(nil)).Elem()

type contextKey struct {
	name string
}

func (k *contextKey) String() string {
	return "github.com/rjeczalik/gh/webhook context value " + k.name
}

type recWriter struct {
	http.ResponseWriter
	status int
}

func (w *recWriter) Underlying() http.ResponseWriter {
	return w.ResponseWriter
}

func (w *recWriter) Write(p []byte) (int, error) {
	w.status = defaultStatus(w.status)
	return w.ResponseWriter.Write(p)
}

func (w *recWriter) WriteHeader(status int) {
	if w.status == 0 {
		w.status = status
		w.ResponseWriter.WriteHeader(status)
	}
}

func (w *recWriter) Flush() {
	if flusher, ok := w.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
		return
	}
	panic("http.ResponseWriter does not implement http.Flusher")
}

var (
	// RequestKey is a context key. It can be used in webhook handlers
	// to access a copy of the *http.Request which is safe to modify
	// and read.
	RequestKey = &contextKey{"request"}

	// ResponseWriterKey is a context key. It can be used in webhook
	// handlers to access the original http.ResponseWriter to write
	// the response directly to client.
	ResponseWriterKey = &contextKey{"response-writer"}
)

// payloadMethods loosly bases around suitableMethods from $GOROOT/src/net/rpc/server.go.
func payloadMethods(typ reflect.Type) map[string]reflect.Method {
	methods := make(map[string]reflect.Method)
LoopMethods:
	for i := 0; i < typ.NumMethod(); i++ {
		method := typ.Method(i)
		mtype := method.Type
		mname := method.Name
		if method.PkgPath != "" {
			continue LoopMethods
		}
		switch mtype.NumIn() {
		case 2:
			eventType := mtype.In(1)
			if eventType.Kind() != reflect.Ptr {
				log.Println("method", mname, "takes wrong type of event:", eventType)
				continue LoopMethods
			}
			event, ok := payloads.Name(eventType.Elem())
			if !ok {
				log.Println("method", mname, "takes wrong type of event:", eventType)
				continue LoopMethods
			}
			if _, ok = methods[event]; ok {
				panic(fmt.Sprintf("there is more than one method handling %v event", eventType))
			}
			methods[event] = method
		case 3:
			if mtype.In(1).Implements(contextType) && mtype.In(2).Kind() == reflect.Ptr {
				eventType := mtype.In(2)
				event, ok := payloads.Name(eventType.Elem())
				if !ok {
					log.Println("method", mname, "takes wrong type of event:", eventType)
					continue LoopMethods
				}
				if _, ok = methods[event]; ok {
					panic(fmt.Sprintf("there is more than one method handling %v event", eventType))
				}
				methods[event] = method
				continue
			}
			if mtype.In(1).Kind() != reflect.String || mtype.In(2) != empty {
				log.Println("wildcard method", mname, "takes wrong types of arguments")
				continue LoopMethods
			}
			if _, ok := methods["*"]; ok {
				panic("there is more than one method handling all events")
			}
			methods["*"] = method
		default:
			log.Println("method", mname, "takes wrong number of arguments:", mtype.NumIn())
			continue LoopMethods
		}
	}
	return methods
}

func hmacHexDigest(secret string, p []byte) string {
	mac := hmac.New(sha1.New, []byte(secret))
	mac.Write(p)
	return hex.EncodeToString(mac.Sum(nil))
}

// Handler is a middleware that handles webhook's HTTP requests.
type Handler struct {
	// ErrorLog specifies an optional logger for errors serving requests.
	// If nil, logging goes to os.Stderr via the log package's standard logger.
	ErrorLog *log.Logger

	// ContextFunc generates context with given http.Request
	// If nil, event handlers creates empty context objects
	ContextFunc func(*http.Request) context.Context

	secret string                    // value for X-Hub-Signature
	rcvr   reflect.Value             // receiver of methods for the service
	method map[string]reflect.Method // event handling methods
}

// New creates new middleware and registers receiver's method for event handling.
// It panics if receiver has multiple methods that take the same type of event
// as an argument.
func New(secret string, rcvr interface{}) *Handler {
	if secret == "" {
		panic("webhook: called New with empty secret")
	}
	return &Handler{
		secret: secret,
		rcvr:   reflect.ValueOf(rcvr),
		method: payloadMethods(reflect.TypeOf(rcvr)),
	}
}

// ServeHTTP implements the http.Handler interface.
func (h *Handler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	event := req.Header.Get("X-GitHub-Event")
	sig := strings.Split(req.Header.Get("X-Hub-Signature"), "=")
	switch content := strings.Split(req.Header.Get("Content-Type"), ";"); {
	case req.Method != "POST":
		h.fatal(w, req, http.StatusMethodNotAllowed, errMethod)
		return
	case req.ContentLength <= 0 || req.ContentLength > maxPayloadLen:
		h.fatal(w, req, http.StatusBadRequest, errHeaders)
		return
	case event == "" || len(sig) != 2:
		h.fatal(w, req, http.StatusBadRequest, errHeaders)
		return
	case sig[0] != "sha1":
		h.fatal(w, req, http.StatusBadRequest, errSigKind)
		return
	case len(content) == 0 || content[0] != "application/json":
		h.fatal(w, req, http.StatusBadRequest, errContentType)
		return
	}
	body := bytes.NewBuffer(make([]byte, 0, int(req.ContentLength)))
	if _, err := io.Copy(body, req.Body); err != nil {
		h.fatal(w, req, http.StatusInternalServerError, err)
		return
	}
	if !hmac.Equal([]byte(hmacHexDigest(h.secret, body.Bytes())), []byte(sig[1])) {
		h.fatal(w, req, http.StatusUnauthorized, errSig)
		return
	}
	typ, ok := payloads.Type(event)
	if !ok {
		h.fatal(w, req, http.StatusBadRequest, errPayload)
		return
	}
	v := reflect.New(typ)
	if err := json.NewDecoder(body).Decode(v.Interface()); err != nil {
		h.fatal(w, req, http.StatusBadRequest, err)
		return
	}
	reqCopy := copyRequest(req)
	reqCopy.Body = ioutil.NopCloser(bytes.NewReader(body.Bytes()))
	reqCopy.ContentLength = int64(body.Len())
	go h.handle(event, v.Interface(), w, reqCopy)
}

func (h *Handler) handle(event string, payload interface{}, w http.ResponseWriter, req *http.Request) {
	if method, ok := h.method[event]; ok {
		status := h.call(method, event, payload, w, req)
		if status == 0 {
			w.WriteHeader(http.StatusNoContent)
		}
		h.logf("INFO %s: Status=%d X-GitHub-Event=%q Type=%T", req.RemoteAddr, defaultStatus(status), event, payload)
		return
	}
	if all, ok := h.method["*"]; ok {
		all.Func.Call([]reflect.Value{h.rcvr, reflect.ValueOf(event), reflect.ValueOf(payload)})
		w.WriteHeader(http.StatusNoContent)
		h.logf("INFO %s: Status=204 X-GitHub-Event=%q Type=%T", req.RemoteAddr, event, payload)
		return
	}
	if event == "ping" {
		w.WriteHeader(http.StatusNoContent)
		h.logf("INFO %s: Status=204 X-GitHub-Event=ping Events=%v", req.RemoteAddr, payload.(*PingEvent).Hook.Events)
	}
}

func (h *Handler) call(method reflect.Method, event string, payload interface{}, w http.ResponseWriter, req *http.Request) int {
	switch method.Type.NumIn() {
	case 2: // without context
		method.Func.Call([]reflect.Value{h.rcvr, reflect.ValueOf(payload)})
		return 0
	case 3: // with context
		var ctx context.Context
		var ww = &recWriter{ResponseWriter: w}
		if h.ContextFunc != nil {
			ctx = h.ContextFunc(req)
		} else {
			ctx = context.Background()
		}

		w = ww

		ctx = context.WithValue(ctx, RequestKey, req)
		ctx = context.WithValue(ctx, ResponseWriterKey, w)
		method.Func.Call([]reflect.Value{h.rcvr, reflect.ValueOf(ctx), reflect.ValueOf(payload)})
		return ww.status
	default:
		return http.StatusInternalServerError
	}
}

func (h *Handler) fatal(w http.ResponseWriter, req *http.Request, code int, err error) {
	h.logf("ERROR %s: Status=%d X-GitHub-Event=%q Content-Length=%d: %v", req.RemoteAddr,
		code, req.Header.Get("X-GitHub-Event"), req.ContentLength, err)
	http.Error(w, err.Error(), code)
}

func (h *Handler) logf(format string, args ...interface{}) {
	if h.ErrorLog != nil {
		h.ErrorLog.Printf(format, args...)
	} else {
		log.Printf(format, args...)
	}
}

// copyRequest was stolen from:
//
//   https://github.com/golang/gddo/blob/b828973/httputil/transport.go#L124-L134
//
func copyRequest(req *http.Request) *http.Request {
	req2 := new(http.Request)
	*req2 = *req
	req2.URL = new(url.URL)
	*req2.URL = *req.URL
	req2.Header = make(http.Header, len(req.Header))
	for k, s := range req.Header {
		req2.Header[k] = append([]string(nil), s...)
	}
	return req2
}

func defaultStatus(status int) int {
	if status != 0 {
		return status
	}
	return 200
}
