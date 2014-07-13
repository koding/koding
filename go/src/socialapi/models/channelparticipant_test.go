package models

import (
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelparticipantNewChannelParticipant(t *testing.T) {
	Convey("while testing New Channel Participant", t, func() {
		Convey("Function call should return ChannelParticipant", func() {
			So(NewChannelParticipant(), ShouldNotBeNil)
		})
	})
}

func TestChannelparticipantGetId(t *testing.T) {
	Convey("While testing get id", t, func() {
		Convey("Initialized struct", func() {
			Convey("should return given id", func() {
				c := ChannelParticipant{Id: 45}
				So(c.GetId(), ShouldEqual, 45)
			})
		})
		Convey("Uninitialized struct", func() {
			Convey("should return 0", func() {
				So(NewChannelParticipant().GetId(), ShouldEqual, 0)
			})
			So(NewChannelParticipant, ShouldNotBeNil)
		})
	})
}

func TestChannelParticipantTableName(t *testing.T) {
	Convey("While getting table name", t, func() {
		Convey("table names should match", func() {
			c := ChannelParticipant{}
			So(c.TableName(), ShouldEqual, "api.channel_participant")
		})
	})
}

func TestChannelParticipantBeforeUpdate(t *testing.T) {
	Convey("While testing before update", t, func() {
		Convey("LastSeenAt should be updated", func() {
			lastSeenAt := time.Now().UTC()

			account, err := createAccount()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)

			c := NewChannelParticipant()
			c.LastSeenAt = lastSeenAt
			c.AccountId = account.Id

			// call before update
			err = c.BeforeUpdate()

			// make sure err is nil
			So(err, ShouldBeNil)
			// check preset last seen at is not same after calling
			// before update function
			So(c.LastSeenAt, ShouldNotEqual, lastSeenAt)
		})
	})
}
