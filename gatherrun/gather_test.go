package gatherrun

import (
	"fmt"
	"net/http"
	"testing"

	. "github.com/koding/klient/Godeps/_workspace/src/github.com/smartystreets/goconvey/convey"
)

func TestGather(t *testing.T) {
	Convey("It should create temporary folder", t, func() {
		fetcher := newTestFetcher()
		exporter, err := newTestExporter()
		So(err, ShouldBeNil)

		g := New(fetcher, exporter, nil)
		err = g.CreateDestFolder()
		So(err, ShouldBeNil)

		defer g.Cleanup()

		folderExists, err := exists(g.DestFolder)
		So(err, ShouldBeNil)

		So(folderExists, ShouldBeTrue)
	})

	Convey("It should download scripts to specified folder", t, func() {
		fetcher := newTestFetcher()
		exporter, err := newTestExporter()
		So(err, ShouldBeNil)

		g := New(fetcher, exporter, nil)
		_, err = g.GetGatherBinary()
		So(err, ShouldBeNil)

		folderExists, err := exists(g.DestFolder + "/" + fetcher.GetFileName())
		So(err, ShouldBeNil)

		So(folderExists, ShouldBeTrue)
	})

	Convey("It should run scripts & export results", t, func() {
		fetcher := newTestFetcher()

		handler := func(w http.ResponseWriter, r *http.Request) {
			Convey("Then it should make proper request", t, func() {
				So(r.Method, ShouldEqual, "POST")
			})

			fmt.Fprintln(w, "{}")
		}

		exporter, err := newTestExporterHandler(handler)
		So(err, ShouldBeNil)

		g := New(fetcher, exporter, nil)
		err = g.Run()
		So(err, ShouldBeNil)
	})
}
