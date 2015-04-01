package emailsender

import (
	"testing"

	"github.com/koding/eventexporter/eventexportertest"
	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func startRunner() *runner.Runner {
	r := runner.New("emailsender_test")
	if err := r.Init(); err != nil {
		panic(err)
	}

	return r
}

func TestBongoName(t *testing.T) {
	r := startRunner()
	defer r.Close()

	Convey("Given 'Mail' model", t, func() {
		Convey("Then it should've right bongo name", func() {
			name := (&Mail{}).BongoName()
			So(name, ShouldEqual, "api.mail")
		})
	})

}

func TestNew(t *testing.T) {
	r := startRunner()
	defer r.Close()

	Convey("Given an exporter client", t, func() {
		Convey("Then it should call it", func() {
			mail := &Mail{
				To:         "mehmet@koding.com",
				Subject:    "Test message",
				Text:       "Example",
				From:       "team@koding.com",
				Properties: &Properties{Username: "mehmet"},
			}

			exporter := eventexportertest.NewFakeExporter()
			c := New(exporter, r.Log)

			err := c.Process(mail)
			So(err, ShouldBeNil)

			So(len(exporter.Events), ShouldEqual, 1)
		})
	})
}
