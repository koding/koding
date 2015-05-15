package gather

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestExporter(t *testing.T) {
	Convey("It should return error if server is unavailable", t, func() {
		exporter := NewEsExporter("localhost1", "gather")

		err := exporter.SendResult(Result{})
		So(err, ShouldNotBeNil)
	})

	Convey("It should export documents", t, func() {
		handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			Convey("Then it should make proper request", t, func() {
				So(r.Method, ShouldEqual, "POST")
				So(r.URL.String(), ShouldEqual, "/gather/document")
			})

			fmt.Fprintln(w, "{}")
		})

		ts := httptest.NewServer(handler)
		defer ts.Close()

		parsedUrl, err := url.Parse(ts.URL)
		So(err, ShouldBeNil)

		ss := strings.Split(parsedUrl.Host, ":")
		host, port := ss[0], ss[1]

		exporter := NewEsExporter(host, "gather")
		exporter.Client.Port = port

		err = exporter.SendResult(Result{})
		So(err, ShouldBeNil)
	})
}
