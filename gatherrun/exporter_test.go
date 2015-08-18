package gatherrun

import (
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	. "github.com/koding/klient/Godeps/_workspace/src/github.com/smartystreets/goconvey/convey"
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

	exporter := NewKodingExporter()
	exporter.URI = parsedUrl.String()

	return exporter, nil
}

func TestExporter(t *testing.T) {
	Convey("It should return error if server is unavailable", t, func() {
		exporter := NewKodingExporter()
		exporter.URI = "localhost:2939"

		err := exporter.SendStats(nil)
		So(err, ShouldNotBeNil)
	})

	Convey("It should export documents", t, func() {
		handler := func(w http.ResponseWriter, r *http.Request) {
			Convey("Then it should make proper request", t, func() {
				So(r.Method, ShouldEqual, "POST")
				So(r.URL.String(), ShouldEqual, "/ingest")
			})

			fmt.Fprintln(w, "{}")
		}

		exporter, err := newTestExporterHandler(handler)
		So(err, ShouldBeNil)

		result := &GatherStat{
			Stats: []GatherSingleStat{
				GatherSingleStat{"test metric", "number", 1},
			},
		}

		err = exporter.SendStats(result)
		So(err, ShouldBeNil)
	})

	Convey("It should export errors", t, func() {
		handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			Convey("Then it should make proper request", t, func() {
				So(r.Method, ShouldEqual, "POST")
				So(r.URL.String(), ShouldEqual, "/errors")
			})

			fmt.Fprintln(w, "{}")
		})

		exporter, err := newTestExporterHandler(handler)
		So(err, ShouldBeNil)

		gErr := &GatherError{Errors: []error{errors.New("Something went wrong!")}}

		err = exporter.SendError(gErr)
		So(err, ShouldBeNil)
	})
}
