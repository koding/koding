package models

import (
	"socialapi/workers/common/runner"
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

func TestChannelParticipantIsParticipant(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While testing is participant", t, func() {
		Convey("it should have channel id", func() {
			cp := NewChannelParticipant()

			ip, err := cp.IsParticipant(1123)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
			So(ip, ShouldEqual, false)
		})

		Convey("it should return false if account is not exist", func() {
			cp := NewChannelParticipant()
			cp.ChannelId = 120

			ip, err := cp.IsParticipant(112345)
			So(err, ShouldBeNil)
			So(ip, ShouldEqual, false)
		})

		Convey("it should not have error if account is exist", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)
			cp := NewChannelParticipant()
			cp.ChannelId = c.Id
			cp.AccountId = acc.Id
			So(cp.Create(), ShouldBeNil)

			_, err := c.AddParticipant(acc.Id)

			ip, err := cp.IsParticipant(acc.Id)
			So(err, ShouldBeNil)
			So(ip, ShouldEqual, true)
			So(cp.StatusConstant, ShouldEqual, ChannelParticipant_STATUS_ACTIVE)
		})
	})
}

func TestChannelParticipantFetchParticipantCount(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While fetching participant count", t, func() {
		Convey("it should have channel id", func() {
			cp := NewChannelParticipant()

			fp, err := cp.FetchParticipantCount()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
			So(fp, ShouldEqual, 0)
		})

		Convey("it should return participant count successfully", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)
			acc1 := createAccountWithTest()
			So(acc1.Create(), ShouldBeNil)
			cp := NewChannelParticipant()
			cp.ChannelId = c.Id
			cp.AccountId = acc.Id
			So(cp.Create(), ShouldBeNil)

			c.AddParticipant(acc.Id)
			c.AddParticipant(acc1.Id)

			ip, err := cp.FetchParticipantCount()
			So(err, ShouldBeNil)
			So(ip, ShouldNotEqual, 2)

		})
	})

}
