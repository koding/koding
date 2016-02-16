package util

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMatchFullOrShortcut(t *testing.T) {
	Convey("Should return false when no item matches", t, func() {
		items := []string{"apple", "banana"}
		_, ok := MatchFullOrShortcut(items, "coconut")
		So(ok, ShouldBeFalse)
	})

	Convey("Should return partially matched item", t, func() {
		items := []string{"apple", "banana"}
		item, ok := MatchFullOrShortcut(items, "a")
		So(ok, ShouldBeTrue)
		So(item, ShouldEqual, "apple")
	})

	Convey("Should return fully matched item", t, func() {
		items := []string{"apple", "apple1"}
		item, ok := MatchFullOrShortcut(items, "apple")
		So(ok, ShouldBeTrue)
		So(item, ShouldEqual, "apple")
	})
}
