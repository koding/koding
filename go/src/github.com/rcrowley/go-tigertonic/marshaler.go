package tigertonic

import (
	"encoding/json"
	"fmt"
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
func (m *Marshaler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	wHeader := w.Header()
	if !acceptJSON(r) {
		wHeader.Set("Content-Type", "text/plain")
		w.WriteHeader(http.StatusNotAcceptable)
		fmt.Fprintf(
			w,
			"\"%s\" does not contain \"application/json\"",
			r.Header.Get("Accept"),
		)
		return
	}
	wHeader.Set("Content-Type", "application/json")
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
			writeJSONError(w, NewMarshalerError(
				"empty interface is not suitable for %s request bodies",
				r.Method,
			))
			return
		}
		if !strings.HasPrefix(
			r.Header.Get("Content-Type"),
			"application/json",
		) {
			writeJSONError(w, NewHTTPEquivError(NewMarshalerError(
				"Content-Type header is %s, not application/json",
				r.Header.Get("Content-Type"),
			), http.StatusUnsupportedMediaType))
			return
		}
		decoder := reflect.ValueOf(json.NewDecoder(r.Body))
		out := decoder.MethodByName("Decode").Call([]reflect.Value{rq})
		if !out[0].IsNil() {
			writeJSONError(w, NewHTTPEquivError(
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
			writeJSONError(w, err)
		} else {
			writeJSONError(w, NewHTTPEquivError(err, code))
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
	w.WriteHeader(code)
	if nil != rs && http.StatusNoContent != code && (out[2].Kind() != reflect.Ptr || !out[2].IsNil()) {
		if err := json.NewEncoder(w).Encode(rs); nil != err {
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
