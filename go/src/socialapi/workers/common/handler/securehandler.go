package handler

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"reflect"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/rcrowley/go-tigertonic"
)

type Securer struct {
	v              reflect.Value
	securer        reflect.Value // this holds the securer handler, customized
	permissionName string        // this holds the permision name for securer function
}

// this function is copied from https://github.com/rcrowley/go-
// tigertonic/blob/master/marshaler.go#L25 while it is working with json data,
// it is also providing secure request mechanism i tried to keep the changeset
// as small as possible.
//
// Changes:
// 		function signature, added "securer interface{}, permissionName string"
//  	struct initialization, "added two new fields"
func Secure(i interface{}, securer interface{}, permissionName string) *Securer {
	t := reflect.TypeOf(i)
	if reflect.Func != t.Kind() {
		panic(NewSecurerError("kind was %v, not Func", t.Kind()))
	}
	if 2 != t.NumIn() && 3 != t.NumIn() && 4 != t.NumIn() {
		panic(NewSecurerError(
			"input arity was %v, not 2, 3, or 4",
			t.NumIn(),
		))
	}
	if "*url.URL" != t.In(0).String() {
		panic(NewSecurerError(
			"type of first argument was %v, not *url.URL",
			t.In(0),
		))
	}
	if "http.Header" != t.In(1).String() {
		panic(NewSecurerError(
			"type of second argument was %v, not http.Header",
			t.In(1),
		))
	}
	if 4 != t.NumOut() {
		panic(NewSecurerError("output arity was %v, not 4", t.NumOut()))
	}
	if reflect.Int != t.Out(0).Kind() {
		panic(NewSecurerError(
			"type of first return value was %v, not int",
			t.Out(0),
		))
	}
	if "http.Header" != t.Out(1).String() {
		panic(NewSecurerError(
			"type of second return value was %v, not http.Header",
			t.Out(1),
		))
	}
	if !t.Out(2).Implements(reflect.TypeOf((*interface{})(nil)).Elem()) {
		panic(NewSecurerError(
			"type of third return value was %v, not a pointer to a response struct",
			t.Out(2),
		))
	}
	if "error" != t.Out(3).String() {
		panic(NewSecurerError(
			"type of fourth return value was %v, not error",
			t.Out(3),
		))
	}
	return &Securer{
		v:              reflect.ValueOf(i),
		securer:        createSecurerSignature(t, securer),
		permissionName: permissionName,
	}
}

// createSecurerSignature checks and creates securer for processing
// panics if signature is not correct
func createSecurerSignature(handler reflect.Type, securer interface{}) reflect.Value {
	t := reflect.TypeOf(securer)

	if reflect.Func != t.Kind() {
		panic(NewSecurerError("kind was %v, not Func", t.Kind()))
	}

	if t.NumIn() != 2 && t.NumIn() != 3 {
		panic(NewSecurerError(
			"input arity was %v, not 2 or 3", t.NumIn(),
		))
	}

	// last param should be "*models.Context"
	if "*models.Context" != t.In(t.NumIn()-1).String() {
		panic(NewSecurerError(
			"type of first argument was %v, not *models.Context",
			t.In(t.NumIn()-1),
		))
	}

	if t.NumIn() == 3 && handler.In(2).String() != t.In(1).String() {
		panic(NewSecurerError(
			"type of second argument was %v, not %v",
			t.In(2), handler.In(2),
		))
	}

	if t.NumOut() != 1 {
		panic(NewSecurerError("output arity was %v, not 1", t.NumOut()))
	}

	if "error" != t.Out(0).String() {
		panic(NewSecurerError(
			"type of first return value was %v, not error",
			t.Out(0),
		))
	}

	return reflect.ValueOf(securer)
}

// ServeHTTP unmarshals JSON input, handles the request via the function, and
// marshals JSON output. Before processing the request it checks if the context
// is allowed to operate
//
// This function is also shamelessly copied fromhttps://github.com/rcrowley/go-
// tigertonic/blob/master/marshaler.go#L25 Only addition to that function is
// "securer.Call"
func (m *Securer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
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
			writeJSONError(w, NewSecurerError(
				"empty interface is not suitable for %s request bodies",
				r.Method,
			))
			return
		}
		if !strings.HasPrefix(
			r.Header.Get("Content-Type"),
			"application/json",
		) {
			writeJSONError(w, tigertonic.NewHTTPEquivError(NewSecurerError(
				"Content-Type header is %s, not application/json",
				r.Header.Get("Content-Type"),
			), http.StatusUnsupportedMediaType))
			return
		}
		decoder := reflect.ValueOf(json.NewDecoder(r.Body))
		out := decoder.MethodByName("Decode").Call([]reflect.Value{rq})
		if !out[0].IsNil() {
			writeJSONError(w, tigertonic.NewHTTPEquivError(
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

	contextValue := reflect.ValueOf(tigertonic.Context(r))

	var permissionReq reflect.Value
	if rq == nilRequest {
		in := m.v.Type().In(1)
		permissionReq = reflect.New(in.Elem())
	} else {
		permissionReq = rq
	}

	var secureRes []reflect.Value

	switch m.securer.Type().NumIn() {
	case 2:
		secureRes = m.securer.Call([]reflect.Value{
			reflect.ValueOf(m.permissionName),
			contextValue,
		})

	case 3:
		secureRes = m.securer.Call([]reflect.Value{
			reflect.ValueOf(m.permissionName),
			permissionReq,
			contextValue,
		})
	}

	if !secureRes[0].IsNil() {
		err := secureRes[0].Interface().(error)
		writeJSONError(w, tigertonic.NewHTTPEquivError(err, 403 /*forbidden*/))
		return
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
			contextValue,
		})
	default:
		panic(m.v.Type())
	}
	code := int(out[0].Int())
	header := out[1].Interface().(http.Header)
	rs := out[2].Interface()
	if !out[3].IsNil() {
		err := out[3].Interface().(error)
		if _, ok := err.(tigertonic.HTTPEquivError); ok {
			writeJSONError(w, err)
		} else {
			writeJSONError(w, tigertonic.NewHTTPEquivError(err, code))
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

// Below this line is from tigertonic package, Error name is changed

// SecurerError is the response body for some 500 responses and panics
// when a handler function is not suitable.
type SecurerError string

func NewSecurerError(format string, args ...interface{}) SecurerError {
	return SecurerError(fmt.Sprintf(format, args...))
}

func (e SecurerError) Error() string { return string(e) }

var nilRequest = reflect.ValueOf((*interface{})(nil))

func errorStatusCode(err error) int {
	if httpEquivError, ok := err.(tigertonic.HTTPEquivError); ok {
		return httpEquivError.StatusCode()
	}
	return http.StatusInternalServerError
}

func writeJSONError(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(errorStatusCode(err))
	if jsonErr := json.NewEncoder(w).Encode(map[string]string{
		"description": err.Error(),
		"error":       errorName(err, "error"),
	}); nil != jsonErr {
		log.Printf("Error marshalling error response into JSON output: %s", jsonErr)
	}
}

func acceptJSON(r *http.Request) bool {
	accept := r.Header.Get("Accept")
	if "" == accept {
		return true
	}
	return strings.Contains(accept, "*/*") || strings.Contains(accept, "application/json")
}

func errorName(err error, fallback string) string {
	if namedError, ok := err.(tigertonic.NamedError); ok {
		if name := namedError.Name(); "" != name {
			return name
		}
	}
	if httpEquivError, ok := err.(tigertonic.HTTPEquivError); ok && tigertonic.SnakeCaseHTTPEquivErrors {
		return strings.Replace(
			strings.ToLower(http.StatusText(httpEquivError.StatusCode())),
			" ",
			"_",
			-1,
		)
	}
	t := reflect.TypeOf(err)
	if reflect.Ptr == t.Kind() {
		t = t.Elem()
	}
	if r, _ := utf8.DecodeRuneInString(t.Name()); unicode.IsLower(r) {
		return fallback
	}
	return t.String()
}
