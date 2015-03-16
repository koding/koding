package models

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetSitemapLocation(t *testing.T) {
	Convey("Test sitemap location for static pages", t, func() {
		sf := SitemapFile{}
		sf.Name = "testing1"
		sf.isStatic = true

		location := GetSitemapLocation(sf)
		So(location, ShouldEqual, sf.Name)

		sf.isStatic = false
		location = GetSitemapLocation(sf)
		So(location, ShouldEqual, "sitemap/testing1.xml")

	})
}
