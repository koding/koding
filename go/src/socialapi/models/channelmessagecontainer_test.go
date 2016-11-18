package models

import (
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelMessageContainerNewChannelMessageContainer(t *testing.T) {

	c := NewChannelMessageContainer()

	Convey("given a NewChannelMessageContainer", t, func() {

		Convey("it should not be nil", func() {
			So(c, ShouldNotBeEmpty)
		})
	})
}

func TestChannelMessageContainerBongoName(t *testing.T) {
	Convey("while testing table name", t, func() {
		Convey("it should not be empty", func() {
			cmc := NewChannelMessageContainer()
			So(cmc.BongoName(), ShouldNotBeEmpty)
		})

		Convey("it should be api.channel_message", func() {
			cmc := NewChannelMessageContainer()
			So(cmc.BongoName(), ShouldEqual, "api.channel_message")
		})
	})
}

func TestChannelMessageContainerGetId(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while getting id", t, func() {
			Convey("it should be zero value if channel message is not exist", func() {
				cmc := NewChannelMessageContainer()

				gi := cmc.GetId()
				So(gi, ShouldEqual, 0)
			})
		})
	})
}

func TestChannelMessageContainerAddAccountOldId(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while adding account old id", t, func() {
			Convey("it should be empty account old if channel is not set", func() {
				cmc := NewChannelMessageContainer()

				gi := cmc.AddAccountOldId()
				So(gi.AccountOldId, ShouldEqual, "")
			})

			Convey("it should add account old id successfully ", func() {
				// create account
				acc := CreateAccountWithTest()
				So(acc.Create(), ShouldBeNil)

				cmc := NewChannelMessageContainer()
				cmc.AccountOldId = acc.OldId

				gi := cmc.AddAccountOldId()
				So(gi.AccountOldId, ShouldEqual, cmc.AccountOldId)
			})
		})
	})
}
