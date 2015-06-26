package webhook

import (
	"socialapi/models"
	"socialapi/request"
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
			So(err, ShouldEqual, ErrNameNotSet)

			i.Name = models.RandomName()
			err = i.Create()
			So(err, ShouldEqual, ErrTitleNotSet)

			i.TypeConstant = ""
			i.Title = models.RandomGroupName()

			err = i.Create()
			So(err, ShouldBeNil)
			So(i.TypeConstant, ShouldEqual, Integration_TYPE_INCOMING)

			i.Id = 0
			err = i.Create()
			So(err, ShouldEqual, ErrNameNotUnique)

			Convey("it should be fetched via name", func() {
				ni := NewIntegration()
				name := models.RandomName()
				err := ni.ByName(name)
				So(err, ShouldEqual, ErrIntegrationNotFound)

				err = ni.ByName(i.Name)
				So(err, ShouldBeNil)
				So(ni.Id, ShouldEqual, i.Id)
			})
		})
	})

}

func TestIntegrationList(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err)
	}
	defer r.Close()

	Convey("while listing an integration", t, func() {
		name1 := "001" + models.RandomGroupName()
		name2 := "000" + models.RandomGroupName()
		firstInt := CreateIntegration(t, name1)
		secondInt := CreateIntegration(t, name2)

		Convey("it should sort integrations by name", func() {
			i := NewIntegration()
			ints, err := i.List(&request.Query{})
			So(err, ShouldBeNil)

			So(len(ints), ShouldBeGreaterThanOrEqualTo, 2)
			So(ints[0].Name, ShouldEqual, name2)
			So(ints[1].Name, ShouldEqual, name1)
		})

		Reset(func() {
			err := firstInt.Delete()
			So(err, ShouldBeNil)

			err = secondInt.Delete()
			So(err, ShouldBeNil)
		})
	})
}

func TestIntegrationSettings(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err)
	}
	defer r.Close()

	Convey("while applying setting to an integration", t, func() {
		Convey("it should able to store events", func() {
			i := NewIntegration()
			i.Name = models.RandomGroupName()
			i.Title = i.Name
			e1 := NewEvent("jumping", "Everybody jump")
			e2 := NewEvent("feeding", "Feed me twice")
			events := NewEvents(e1, e2)
			i.AddEvents(events)
			err := i.Create()
			So(err, ShouldBeNil)

			expectedIntegration := NewIntegration()
			err = expectedIntegration.ByName(i.Name)
			So(err, ShouldBeNil)
			expectedEvents := &Events{}
			err = expectedIntegration.GetSettings("events", expectedEvents)
			So(err, ShouldBeNil)
			eventsArr := []Event(*expectedEvents)
			So(len(eventsArr), ShouldEqual, 2)
			So(eventsArr[0].Name, ShouldEqual, "jumping")
		})
	})
}
