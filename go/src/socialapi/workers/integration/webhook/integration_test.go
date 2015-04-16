package webhook

import (
	"socialapi/models"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestIntegrationCreate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err)
	}
	defer r.Close()

	Convey("while creating an integration", t, func() {
		Convey("it should contain both title and type constant", func() {
			i := NewIntegration()
			i.TypeConstant = Integration_TYPE_INCOMING
			err := i.Create()
			So(err, ShouldEqual, ErrTitleNotSet)

			i.TypeConstant = ""
			i.Title = models.RandomName()

			err = i.Create()
			So(err, ShouldBeNil)
			So(i.TypeConstant, ShouldEqual, Integration_TYPE_INCOMING)

			i.Id = 0
			err = i.Create()
			So(err, ShouldEqual, ErrTitleNotUnique)
		})
	})
}
