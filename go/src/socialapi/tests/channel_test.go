package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelCreation(t *testing.T) {
	Convey("while  testing channel", t, func() {
		Convey("First Create User", func() {

			Convey("we should be able to create it", nil)

			Convey("we should be able to update it", nil)

			Convey("owner should be able to add new participants into it", nil)

			Convey("normal user shouldnt be able to add new participants from it", nil)

			Convey("owner should be able to remove new participants into it", nil)

			Convey("normal user shouldnt be able to remove new participants from it", nil)
		})
	})
}
