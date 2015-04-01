package models

import (
	"testing"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/runner"

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

func TestChannelParticipantBongoName(t *testing.T) {
	Convey("While getting table name", t, func() {
		Convey("table names should match", func() {
			c := ChannelParticipant{}
			So(c.BongoName(), ShouldEqual, "api.channel_participant")
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
			acc := CreateAccountWithTest()
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

			_, err := cp.FetchParticipantCount()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
		})

		Convey("it should have zero value if account is not exist in the channel", func() {
			cp := NewChannelParticipant()
			cp.ChannelId = 2442

			fp, err := cp.FetchParticipantCount()
			So(err, ShouldBeNil)
			So(fp, ShouldEqual, 0)
		})

		Convey("it should return participant count successfully", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)
			acc1 := CreateAccountWithTest()
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

func TestChannelParticipantgetAccountId(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While getting account id", t, func() {
		Convey("it should have channel id", func() {
			cp := NewChannelParticipant()

			gai, err := cp.getAccountId()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "couldnt find accountId from content")
			So(gai, ShouldEqual, 0)
		})

		Convey("it should have error if account is not exist", func() {
			cp := NewChannelParticipant()
			cp.Id = 123145

			gai, err := cp.getAccountId()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
			So(gai, ShouldEqual, 0)
		})

		Convey("it should return account id if account is exist", func() {
			// create account
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			cp := NewChannelParticipant()
			cp.Id = 1201
			cp.AccountId = acc.Id

			gai, err := cp.getAccountId()
			So(err, ShouldBeNil)
			So(gai, ShouldEqual, acc.Id)
		})

	})

}

func TestChannelParticipantFetchParticipant(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While fetching participant", t, func() {
		Convey("it should have error if channel id is not set", func() {
			cp := NewChannelParticipant()

			err := cp.FetchParticipant()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
		})

		Convey("it should have error if account id is not set", func() {
			cp := NewChannelParticipant()
			cp.ChannelId = 1453

			err := cp.FetchParticipant()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrAccountIdIsNotSet)
		})

		Convey("it should have error if account is not exist", func() {
			cp := NewChannelParticipant()
			cp.ChannelId = 1453
			cp.AccountId = 1454

			err := cp.FetchParticipant()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
		})

		Convey("it should not have any error if account is exist in channel", func() {
			// create account
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			_, errr := c.AddParticipant(acc.Id)
			So(errr, ShouldBeNil)

			cp := NewChannelParticipant()
			cp.ChannelId = c.Id
			cp.AccountId = acc.Id

			err := cp.FetchParticipant()
			So(err, ShouldBeNil)
		})
	})
}

func TestChannelParticipantFetchActiveParticipant(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While fetching active participant", t, func() {
		Convey("it should have error if channel id is not set", func() {
			cp := NewChannelParticipant()

			err := cp.FetchParticipant()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
		})

		Convey("it should return active participant successfully", func() {
			// create account
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			_, errr := c.AddParticipant(acc.Id)
			So(errr, ShouldBeNil)

			cp := NewChannelParticipant()
			cp.ChannelId = c.Id
			cp.AccountId = acc.Id

			err := cp.FetchActiveParticipant()
			So(err, ShouldBeNil)
		})

		Convey("it should have error if account is not exist in channel", func() {
			// create account
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			_, errr := c.AddParticipant(acc.Id)
			So(errr, ShouldBeNil)

			erro := c.RemoveParticipant(acc.Id)
			So(erro, ShouldBeNil)

			cp := NewChannelParticipant()
			cp.ChannelId = c.Id
			cp.AccountId = acc.Id

			err := cp.FetchActiveParticipant()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
		})

	})
}

func TestChannelParticipantMarkIfExempt(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While marking if participant is exempt", t, func() {
		Convey("it should be nil if participant is already exempt", func() {
			// create account
			acc := CreateAccountWithTest()
			acc.IsTroll = true
			So(acc.Update(), ShouldBeNil)

			c := createNewChannelWithTest()
			c.CreatorId = acc.Id
			So(c.Create(), ShouldBeNil)

			msg := createMessageWithTest()
			msg.AccountId = acc.Id
			So(msg.Create(), ShouldBeNil)

			_, errs := c.AddMessage(msg)
			So(errs, ShouldBeNil)

			cp := NewChannelParticipant()
			cp.ChannelId = c.Id
			cp.AccountId = acc.Id

			_, erro := c.AddParticipant(acc.Id)
			So(erro, ShouldBeNil)

			err := cp.MarkIfExempt()
			So(err, ShouldBeNil)
		})

		Convey("it should have error if account is not set", func() {
			// create account
			acc := CreateAccountWithTest()
			acc.IsTroll = false
			So(acc.Update(), ShouldBeNil)

			c := createNewChannelWithTest()
			c.CreatorId = acc.Id
			So(c.Create(), ShouldBeNil)

			cp := NewChannelParticipant()
			cp.ChannelId = c.Id

			err := cp.MarkIfExempt()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "couldnt find accountId from content")
		})

	})
}

func TestChannelParticipantisExempt(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("While testing channel participant is exempt or not", t, func() {
		Convey("it should have error while getting account id from db when channel id is not set", func() {
			cp := NewChannelParticipant()

			ex, err := cp.isExempt()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "couldnt find accountId from content")
			So(ex, ShouldEqual, false)
		})

		Convey("it should return true if participant is troll", func() {
			// create account
			acc := CreateAccountWithTest()
			err := acc.MarkAsTroll()
			So(err, ShouldBeNil)

			cp := NewChannelParticipant()
			cp.AccountId = acc.Id

			ex, err := cp.isExempt()
			So(err, ShouldBeNil)
			So(ex, ShouldEqual, true)
		})

		Convey("it should return true if participant is not troll", func() {
			// create account
			acc := CreateAccountWithTest()

			cp := NewChannelParticipant()
			cp.AccountId = acc.Id

			ex, err := cp.isExempt()
			So(err, ShouldBeNil)
			So(ex, ShouldEqual, false)
		})

	})
}
