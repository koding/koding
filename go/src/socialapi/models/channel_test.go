package models

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelCreate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while creating channel", t, func() {
		Convey("", nil)
	})

}

func TestChannelTableName(t *testing.T) {
	Convey("while testing TableName()", t, func() {
		So(NewChannel().TableName(), ShouldEqual, ChannelTableName)
	})
}
