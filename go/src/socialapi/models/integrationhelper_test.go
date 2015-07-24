package models

import (
	"testing"

	"github.com/jinzhu/gorm"
	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelIntegrationMetaPopulate(t *testing.T) {
	Convey("while populating the channel integration meta", t, func() {
		cim := NewChannelIntegrationMeta()
		ci := new(ChannelIntegration)
		i := new(Integration)

		i.Title = "Testing"
		i.IconPath = "http://hehehe.png"

		Convey("it should return integration data when customName is not set", func() {
			cim.Populate(ci, i)

			So(cim.Title, ShouldEqual, i.Title)
			So(cim.IconPath, ShouldEqual, i.IconPath)
		})

		Convey("it should return customName as title when it is set", func() {
			ci.Settings = gorm.Hstore{}
			customName := "Test me"
			ci.Settings["customName"] = &customName

			cim.Populate(ci, i)

			So(cim.Title, ShouldEqual, customName)
			So(cim.IconPath, ShouldEqual, i.IconPath)
		})
	})
}
