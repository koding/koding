package gather

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func newTestExporter(hFn func(w http.ResponseWriter, r *http.Request)) (Exporter, error) {
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

		err := exporter.SendResult(Result{})
		So(err, ShouldNotBeNil)
	})

	Convey("It should export documents", t, func() {
		handler := func(w http.ResponseWriter, r *http.Request) {
			Convey("Then it should make proper request", t, func() {
				So(r.Method, ShouldEqual, "POST")
				So(r.URL.String(), ShouldEqual, "/gather/document")

				var result Result
				err := json.NewDecoder(r.Body).Decode(&result)
				So(err, ShouldBeNil)

				Convey("Then it should have message body", func() {
					So(result["metric"], ShouldEqual, "test metric")
				})
			})

			fmt.Fprintln(w, "{}")
		}

		exporter, err := newTestExporter(handler)
		So(err, ShouldBeNil)

		err = exporter.SendResult(Result{"metric": "test metric"})
		So(err, ShouldBeNil)
	})

	Convey("It should export errors", t, func() {
		handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			Convey("Then it should make proper request", t, func() {
				So(r.Method, ShouldEqual, "POST")
				So(r.URL.String(), ShouldEqual, "/errors/document")

				var result Result
				err := json.NewDecoder(r.Body).Decode(&result)
				So(err, ShouldBeNil)

				Convey("Then it should have message body", func() {
					So(result["message"], ShouldEqual, "test error")
				})
			})

			fmt.Fprintln(w, "{}")
		})

		exporter, err := newTestExporter(handler)
		So(err, ShouldBeNil)

		err = exporter.SendError(errors.New("test error"))
		So(err, ShouldBeNil)
	})
}
