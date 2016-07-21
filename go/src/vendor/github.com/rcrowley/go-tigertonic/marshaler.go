package tigertonic

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"reflect"
	"strings"
)

// Marshaler is an http.Handler that unmarshals JSON input, handles the request
// via a function, and marshals JSON output.  It refuses to answer requests
// without an Accept header that includes the application/json content type.
type Marshaler struct {
	v reflect.Value
}

// Marshaled returns an http.Handler that implements its ServeHTTP method by
// calling the given function, the signature of which must be
//
//     func(*url.URL, http.Header, *Request) (int, http.Header, *Response)
//
// where Request and Response may be any struct type of your choosing.
func Marshaled(i interface{}) *Marshaler {
	t := reflect.TypeOf(i)
	if reflect.Func != t.Kind() {
		panic(NewMarshalerError("kind was %v, not Func", t.Kind()))
	}
	if 2 != t.NumIn() && 3 != t.NumIn() && 4 != t.NumIn() {
		panic(NewMarshalerError(
			"input arity was %v, not 2, 3, or 4",
			t.NumIn(),
		))
	}
	if "*url.URL" != t.In(0).String() {
		panic(NewMarshalerError(
			"type of first argument was %v, not *url.URL",
			t.In(0),
		))
	}
	if "http.Header" != t.In(1).String() {
		panic(NewMarshalerError(
			"type of second argument was %v, not http.Header",
			t.In(1),
		))
	}
	if 4 != t.NumOut() {
		panic(NewMarshalerError("output arity was %v, not 4", t.NumOut()))
	}
	if reflect.Int != t.Out(0).Kind() {
		panic(NewMarshalerError(
			"type of first return value was %v, not int",
			t.Out(0),
		))
	}
	if "http.Header" != t.Out(1).String() {
		panic(NewMarshalerError(
			"type of second return value was %v, not http.Header",
			t.Out(1),
		))
	}
	if !t.Out(2).Implements(reflect.TypeOf((*interface{})(nil)).Elem()) {
		panic(NewMarshalerError(
			"type of third return value was %v, not a pointer to a response struct",
			t.Out(2),
		))
	}
	if "error" != t.Out(3).String() {
		panic(NewMarshalerError(
			"type of fourth return value was %v, not error",
			t.Out(3),
		))
	}
	return &Marshaler{reflect.ValueOf(i)}
}

// ServeHTTP unmarshals JSON input, handles the request via the function, and
// marshals JSON output.
// If the output of the handler function implements io.Reader the headers must
// contain a 'Content-Type'; the stream will be written directly to the
// requestor without being marshaled to JSON.
// Additionally if the output implements the io.Closer the stream will be
// automatically closed after flushing.
func (m *Marshaler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	wHeader := w.Header()
	isReader := false
	isCloser := false
	if 2 < m.v.Type().NumOut() {
		out2 := m.v.Type().Out(2)
		if reflect.Interface == out2.Kind() {
			isReader = out2.Implements(reflect.TypeOf((*io.Reader)(nil)).Elem())
			isCloser = out2.Implements(reflect.TypeOf((*io.Closer)(nil)).Elem())
		}
	}
	if !isReader && !acceptJSON(r) {
		ResponseErrorWriter.WritePlaintextError(w, NewHTTPEquivError(NewMarshalerError(
			"Accept header %q does not allow \"application/json\"",
			r.Header.Get("Accept"),
		), http.StatusNotAcceptable))
		return
	}
	var rq reflect.Value
	if 2 < m.v.Type().NumIn() {
		in2 := m.v.Type().In(2)
		if reflect.Interface == in2.Kind() && 0 == in2.NumMethod() {
			rq = nilRequest
		} else if reflect.Slice == in2.Kind() || reflect.Map == in2.Kind() {
			// non-pointer maps/slices require special treatment because
			// json.Unmarshal won't work on a non-pointer destination. We
			// add a level indirection here, then deref it before .Call()
			rq = reflect.New(in2)
		} else {
			rq = reflect.New(in2.Elem())
		}
	} else {
		rq = nilRequest
	}
	if "PATCH" == r.Method || "POST" == r.Method || "PUT" == r.Method {
		if rq == nilRequest {
			ResponseErrorWriter.WriteError(r, w, NewMarshalerError(
				"empty interface is not suitable for %s request bodies",
				r.Method,
			))
			return
		}
		if !strings.HasPrefix(
			r.Header.Get("Content-Type"),
			"application/json",
		) {
			ResponseErrorWriter.WriteError(r, w, NewHTTPEquivError(NewMarshalerError(
				"Content-Type header is %s, not application/json",
				r.Header.Get("Content-Type"),
			), http.StatusUnsupportedMediaType))
			return
		}
		decoder := reflect.ValueOf(json.NewDecoder(r.Body))
		out := decoder.MethodByName("Decode").Call([]reflect.Value{rq})
		if !out[0].IsNil() {
			ResponseErrorWriter.WriteError(r, w, NewHTTPEquivError(
				out[0].Interface().(error),
				http.StatusBadRequest,
			))
			return
		}
		r.Body.Close()
	} else if nilRequest != rq {
		log.Printf(
			"%s request body isn't an empty interface; this is weird and is being ignored\n",
			r.Method,
		)
	}
	if reflect.Slice == rq.Elem().Kind() || reflect.Map == rq.Elem().Kind() {
		rq = rq.Elem()
	}
	var out []reflect.Value
	switch m.v.Type().NumIn() {
	case 2:
		out = m.v.Call([]reflect.Value{
			reflect.ValueOf(r.URL),
			reflect.ValueOf(r.Header),
		})
	case 3:
		out = m.v.Call([]reflect.Value{
			reflect.ValueOf(r.URL),
			reflect.ValueOf(r.Header),
			rq,
		})
	case 4:
		out = m.v.Call([]reflect.Value{
			reflect.ValueOf(r.URL),
			reflect.ValueOf(r.Header),
			rq,
			reflect.ValueOf(Context(r)),
		})
	default:
		panic(m.v.Type())
	}
	code := int(out[0].Int())
	header := out[1].Interface().(http.Header)
	rs := out[2].Interface()
	if !out[3].IsNil() {
		err := out[3].Interface().(error)
		if _, ok := err.(HTTPEquivError); ok {
			ResponseErrorWriter.WriteError(r, w, err)
		} else {
			ResponseErrorWriter.WriteError(r, w, NewHTTPEquivError(err, code))
		}
		return
	}
	if nil != header {
		for key, values := range header {
			wHeader.Del(key)
			for _, value := range values {
				wHeader.Add(key, value)
			}
		}
	}
	if isReader {
		contentType := wHeader.Get("Content-Type")
		if "" == contentType {
			ResponseErrorWriter.WriteError(r, w, NewHTTPEquivError(NewMarshalerError(
				"Required Content-Type header missing from stream response"),
				http.StatusInternalServerError))
			return
		}
		if !acceptContentType(r, contentType) {
			ResponseErrorWriter.WritePlaintextError(w, NewHTTPEquivError(NewMarshalerError(
				"Accept header %q does not allow %q",
				r.Header.Get("Accept"), contentType,
			), http.StatusNotAcceptable))
			return
		}
	} else {
		wHeader.Set("Content-Type", "application/json")
	}
	w.WriteHeader(code)
	if nil != rs && http.StatusNoContent != code && (out[2].Kind() != reflect.Ptr || !out[2].IsNil()) {
		if isReader {
			reader := rs.(io.Reader)
			_, err := io.Copy(w, reader)
			if nil != err {
				log.Println(err)
			}
			if isCloser {
				closer := rs.(io.Closer)
				if err := closer.Close(); nil != err {
					log.Println(err)
				}
			}
		} else if err := json.NewEncoder(w).Encode(rs); nil != err {
			log.Println(err)
		}
	}
}

// MarshalerError is the response body for some 500 responses and panics
// when a handler function is not suitable.
type MarshalerError string

func NewMarshalerError(format string, args ...interface{}) MarshalerError {
	return MarshalerError(fmt.Sprintf(format, args...))
}

func (e MarshalerError) Error() string { return string(e) }

var nilRequest = reflect.ValueOf((*interface{})(nil))
