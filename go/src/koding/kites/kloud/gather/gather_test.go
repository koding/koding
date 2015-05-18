package gather

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGather(t *testing.T) {
	Convey("It should create temporary folder", t, func() {
		fetcher := getTestFetcher()

		g := New(fetcher)
		err := g.CreateDestFolder()
		So(err, ShouldBeNil)

		folderExists, err := exists(g.DestFolder)
		So(err, ShouldBeNil)

		So(folderExists, ShouldBeTrue)
	})

	Convey("It should download scripts to specified folder", t, func() {
		fetcher := getTestFetcher()

		g := New(fetcher)
		_, err := g.GetScripts()
		So(err, ShouldBeNil)

		folderExists, err := exists(g.DestFolder + "/" + fetcher.ScriptsFile)
		So(err, ShouldBeNil)

		So(folderExists, ShouldBeTrue)
	})

	Convey("It should extract scripts into runnables", t, func() {
		fetcher := getTestFetcher()

		g := New(fetcher)
		scripts, err := g.GetScripts()
		So(err, ShouldBeNil)

		So(len(scripts), ShouldEqual, 1)
		So(scripts[0].Path, ShouldEndWith, "ls")
	})
}
