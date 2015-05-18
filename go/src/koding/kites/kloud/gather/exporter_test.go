package gather

import (
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func newTestExporter() (Exporter, error) {
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "{}")
	})

	return newTestExporterHandler(handler)
}

func newTestExporterHandler(hFn func(w http.ResponseWriter, r *http.Request)) (Exporter, error) {
	ts := httptest.NewServer(http.HandlerFunc(hFn))

	parsedUrl, err := url.Parse(ts.URL)
	if err != nil {
		return nil, err
	}

	ss := strings.Split(parsedUrl.Host, ":")
	host, port := ss[0], ss[1]

	exporter := NewEsExporter(host, "gather")
	exporter.Client.Port = port

	return exporter, nil
}

func TestExporter(t *testing.T) {
	Convey("It should return error if server is unavailable", t, func() {
		exporter := NewEsExporter("localhost1", "gather")

		err := exporter.SendResult(&Result{})
		So(err, ShouldNotBeNil)
	})

	Convey("It should export documents", t, func() {
		handler := func(w http.ResponseWriter, r *http.Request) {
			Convey("Then it should make proper request", t, func() {
				So(r.Method, ShouldEqual, "POST")
				So(r.URL.String(), ShouldEqual, "/gather/document")
			})

			fmt.Fprintln(w, "{}")
		}

		exporter, err := newTestExporterHandler(handler)
		So(err, ShouldBeNil)

		err = exporter.SendResult(&Result{Name: "test metric"})
		So(err, ShouldBeNil)
	})

	Convey("It should export errors", t, func() {
		handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			Convey("Then it should make proper request", t, func() {
				So(r.Method, ShouldEqual, "POST")
				So(r.URL.String(), ShouldEqual, "/errors/document")
			})

			fmt.Fprintln(w, "{}")
		})

		exporter, err := newTestExporterHandler(handler)
		So(err, ShouldBeNil)

		err = exporter.SendError(errors.New("test error"))
		So(err, ShouldBeNil)
	})
}
