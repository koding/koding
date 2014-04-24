package tigertonic

import (
	"fmt"
	"io/ioutil"
	"net/http"
)

type PostProcessor struct {
	handler http.Handler
	f       func(*http.Request, *http.Response)
}

func PostProcessed(
	handler http.Handler,
	f func(*http.Request, *http.Response),
) *PostProcessor {
	return &PostProcessor{
		handler: handler,
		f:       f,
	}
}

func (pp *PostProcessor) ServeHTTP(w0 http.ResponseWriter, r *http.Request) {
	w := NewTeeResponseWriter(w0)
	pp.handler.ServeHTTP(w, r)
	pp.f(r, &http.Response{
		Status: fmt.Sprintf(
			"%d %s",
			w.StatusCode,
			http.StatusText(w.StatusCode),
		),
		StatusCode:    w.StatusCode,
		Proto:         r.Proto,
		ProtoMajor:    r.ProtoMajor,
		ProtoMinor:    r.ProtoMinor,
		Header:        w.Header(),
		Body:          ioutil.NopCloser(&w.Body),
		ContentLength: int64(w.Body.Len()),
	})
}
