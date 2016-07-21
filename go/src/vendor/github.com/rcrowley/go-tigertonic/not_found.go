package tigertonic

import (
	"errors"
	"fmt"
	"net/http"
)

// NotFoundHandler responds 404 to every request, possibly with a JSON body.
type NotFoundHandler struct{}

func (NotFoundHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	notFoundErr := NotFound{Err: errors.New(fmt.Sprintf("%s %s not found", r.Method, r.URL.Path))}
	if acceptJSON(r) {
		ResponseErrorWriter.WriteJSONError(w, notFoundErr)
	} else {
		ResponseErrorWriter.WritePlaintextError(w, notFoundErr)
	}
}
