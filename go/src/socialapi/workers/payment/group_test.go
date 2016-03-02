package payment

import (
	. "github.com/smartystreets/goconvey/convey"
	"testing"
)

func TestSubscriptionsRequest2(t *testing.T) {
	Convey("Given user that belongs to group with no subscription", t, func() {
		Convey("Then it should return 'free' plan", func() {
		})
	})

	Convey("Given user that belongs to group with subscription", t, func() {
		Convey("When subscription is expired", func() {
			Convey("Then it should return the expired subscription", func() {
			})
		})
	})

	Convey("Given user that belongs to group with subscription", t, func() {
		Convey("Then it should return the subscription", func() {
		})
	})
}
