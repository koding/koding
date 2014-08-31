package models

import (
	"socialapi/workers/common/runner"
	"testing"

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

func TestChannelMessageContainerNewInteractionContainer(t *testing.T) {

	c := NewInteractionContainer()

	Convey("given a NewInteractionContainer", t, func() {

		Convey("it should not be nil", func() {
			So(c, ShouldNotBeEmpty)
		})

		Convey("it should have actors preview as set", func() {
			So(c.ActorsPreview, ShouldBeEmpty)
		})

		Convey("it should have isInteracted as set", func() {
			So(c.IsInteracted, ShouldEqual, false)
		})

		Convey("it should have actorscount as set", func() {
			So(c.ActorsCount, ShouldEqual, 0)
		})
	})
}

/*
// function as argument needs to be...
func TestChannelMessageContainerwithChannelMessageContainerChecks(t *testing.T) {
	Convey("while checking channel message container", t, func() {
		Convey("it should have error if channel is empty", func() {
			cmc := NewChannelMessageContainer()

			cc := withChannelMessageContainerChecks(cmc, f)

			So(cc, ShouldNotBeNil)
			So(cc.Err, ShouldEqual, ErrMessageIsNotSet)
		})
	})
}
*/

func TestChannelMessageContainerTableName(t *testing.T) {
	Convey("while testing table name", t, func() {
		Convey("it should not be empty", func() {
			cmc := NewChannelMessageContainer()
			So(cmc.TableName(), ShouldNotBeEmpty)
		})

		Convey("it should be api.channel_message", func() {
			cmc := NewChannelMessageContainer()
			So(cmc.TableName(), ShouldEqual, "api.channel_message")
		})
	})
}

func TestChannelMessageContainerGetId(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while getting id", t, func() {
		Convey("it should be zero value if channel message is not exist", func() {
			cmc := NewChannelMessageContainer()

			gi := cmc.GetId()
			So(gi, ShouldEqual, 0)
		})
		/*
			Convey("it should not have any error if channel message is exist", func() {
				// create message
				c := createMessageWithTest()
				So(c.Create(), ShouldBeNil)

				cmc := NewChannelMessageContainer()
				cmc.Message.Body = c.Body
				cmc.Message.Id = c.Id

				gi := cmc.GetId()
				So(gi, ShouldEqual, c.Id)
			})
		*/

	})
}

func TestChannelMessageContainerAddAccountOldId(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while adding account old id", t, func() {
		Convey("it should be empty account old if channel is not set", func() {
			cmc := NewChannelMessageContainer()

			gi := cmc.AddAccountOldId()
			So(gi.AccountOldId, ShouldEqual, "")
		})

		Convey("it should add account old id successfully ", func() {
			// create account
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			cmc := NewChannelMessageContainer()
			cmc.AccountOldId = acc.OldId

			gi := cmc.AddAccountOldId()
			So(gi.AccountOldId, ShouldEqual, cmc.AccountOldId)
		})
	})
}
