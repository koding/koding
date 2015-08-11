package gatherrun

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"testing"

	. "github.com/koding/klient/Godeps/_workspace/src/github.com/smartystreets/goconvey/convey"
)

func TestGather(t *testing.T) {
	Convey("It should download scripts to specified folder", t, func() {
		fetcher := newTestFetcher()
		exporter, err := newTestExporter()
		So(err, ShouldBeNil)

		g := New(fetcher, exporter, "env", "username", "analytics")
		_, err = g.GetGatherBinary()
		So(err, ShouldBeNil)

		folderExists, err := exists(filepath.Join(g.DestFolder, fetcher.GetFileName()))
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

		g := New(fetcher, exporter, "env", "username", "analytics")
		err = g.Run()
		So(err, ShouldBeNil)
	})
}

func exists(name string) (bool, error) {
	var err error
	if _, err = os.Stat(name); os.IsNotExist(err) {
		return false, nil
	}

	return true, err
}
