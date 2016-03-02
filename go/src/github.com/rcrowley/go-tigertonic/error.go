package tigertonic

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"reflect"
	"strings"
	"unicode"
	"unicode/utf8"
)

func acceptJSON(r *http.Request) bool {
	accept := r.Header.Get("Accept")
	if "" == accept {
		return true
	}
	return strings.Contains(accept, "*/*") || strings.Contains(accept, "application/*") || strings.Contains(accept, "application/json")
}

func acceptContentType(r *http.Request, contentType string) bool {
	accept := r.Header.Get("Accept")
	if "" == accept {
		return true
	}
	if strings.Contains(accept, "*/*") {
		return true
	}
	if strings.Contains(accept, contentType) {
		return true
	}
	typeParts := strings.Split(contentType, "/")
	if len(typeParts) < 2 {
		return false
	}
	return strings.Contains(accept, fmt.Sprintf("%s/*", typeParts[0]))
}

func errorName(err error, fallback string) string {
	if namedError, ok := err.(NamedError); ok {
		if name := namedError.Name(); "" != name {
			return name
		}
	}
	if httpEquivError, ok := err.(HTTPEquivError); ok && SnakeCaseHTTPEquivErrors {
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

func errorStatusCode(err error) int {
	if httpEquivError, ok := err.(HTTPEquivError); ok {
		return httpEquivError.StatusCode()
	}
	return http.StatusInternalServerError
}

// ResponseErrorWriter is a handler for outputting errors to the http.ResponseWriter
var ResponseErrorWriter ErrorWriter = defaultErrorWriter{}

type ErrorWriter interface {
	WriteError(r *http.Request, w http.ResponseWriter, err error)
	WriteJSONError(w http.ResponseWriter, err error)
	WritePlaintextError(w http.ResponseWriter, err error)
}

type defaultErrorWriter struct {
}

func (d defaultErrorWriter) WriteError(r *http.Request, w http.ResponseWriter, err error) {
	if acceptJSON(r) {
		d.WriteJSONError(w, err)
	} else {
		d.WritePlaintextError(w, err)
	}
}

func (d defaultErrorWriter) WriteJSONError(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(errorStatusCode(err))

	errName := errorName(err, "error")
	if SnakeCaseHTTPEquivErrors {
		switch errName {
		case "tigertonic.NotFound":
			errName = "not_found"
		case "tigertonic.MethodNotAllowed":
			errName = "method_not_allowed"
		}
	}

	if jsonErr := json.NewEncoder(w).Encode(map[string]string{
		"description": err.Error(),
		"error":       errName,
	}); nil != jsonErr {
		log.Printf("Error marshalling error response into JSON output: %s", jsonErr)
	}
}

func (d defaultErrorWriter) WritePlaintextError(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(errorStatusCode(err))
	fmt.Fprintf(w, "%s: %s", errorName(err, "error"), err)
}
