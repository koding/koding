package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelParticipantOperations(t *testing.T) {
	Convey("while testing channel participants", t, func() {

		Convey("first we should be able to create dummy channel", func() {

			Convey("anyone can add user to it", nil)

			Convey("creator can remove any account", nil)

			Convey("creator can not do self-remove", nil)

			Convey("account can remove itself", nil)

			Convey("3rd user can not remove any other account", nil)

			Convey("do not allow duplicate participation", nil)

		})

	})
}
