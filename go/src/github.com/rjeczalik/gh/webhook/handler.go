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
	"log"
	"net/http"
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
	w.WriteHeader(http.StatusOK)
	go h.call(req.RemoteAddr, event, v.Interface(), req)
}

func (h *Handler) call(remote, event string, payload interface{}, req *http.Request) {
	if method, ok := h.method[event]; ok {
		mtype := method.Type
		switch mtype.NumIn() {
		case 2: // without context
			method.Func.Call([]reflect.Value{h.rcvr, reflect.ValueOf(payload)})
		case 3: // with context
			var ctx context.Context
			if h.ContextFunc != nil {
				ctx = h.ContextFunc(req)
			} else {
				ctx = context.Background()
			}
			method.Func.Call([]reflect.Value{h.rcvr, reflect.ValueOf(ctx), reflect.ValueOf(payload)})
		}

		h.logf("INFO %s: Status=200 X-GitHub-Event=%q Type=%T", remote, event, payload)
		return
	}
	if all, ok := h.method["*"]; ok {
		all.Func.Call([]reflect.Value{h.rcvr, reflect.ValueOf(event), reflect.ValueOf(payload)})
		h.logf("INFO %s: Status=200 X-GitHub-Event=%q Type=%T", remote, event, payload)
		return
	}
	if event == "ping" {
		h.logf("INFO %s: Status=200 X-GitHub-Event=ping Events=%v", remote, payload.(*PingEvent).Hook.Events)
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
