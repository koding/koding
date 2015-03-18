package models

import (
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCreateStaticPages(t *testing.T) {
	sf := NewSitemapFetcher(time.Second*1, time.Second*1, "http://koding.com")

	Convey("Static pages should be created within sitemap.xml", t, func() {
		staticPages = []string{"testpage1", "testpage2"}
		pages := sf.CreateStaticPages()

		So(len(pages), ShouldEqual, 2)
		So(pages[0].Name, ShouldEqual, "testpage1")
		So(pages[0].isStatic, ShouldBeTrue)
	})
}
