package emailmodels

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/models"
	"testing"
	"time"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRenderChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldn't start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	rand.Seed(time.Now().UnixNano())
	account1, err := models.CreateAccountInBothDbs()
	if err != nil {
		t.Fatalf("error occurred: %s", err)
	}
	account2, err := models.CreateAccountInBothDbs()
	if err != nil {
		t.Fatalf("error occurred: %s", err)
	}

	SkipConvey("Channel should be able to rendered", t, func() {
		cs := &ChannelSummary{}

		cs.UnreadCount = 2
		// cs.Participants := []models.ChannelParticipant{}
		cp1 := models.NewChannelParticipant()
		cp1.Id = 1
		cp1.AccountId = account1.Id

		cs.Participants = []models.ChannelParticipant{*cp1}
		ms1 := &MessageSummary{}
		ms1.Body = "hehe"
		ms1.Nickname = account1.Nick
		cs.MessageSummaries = append(cs.MessageSummaries, ms1)

		Convey("Direct message text must be shown when it is direct message", func() {
			body, err := cs.Render()
			So(err, ShouldBeNil)
			So(body, ShouldContainSubstring, "hehe")
			So(body, ShouldContainSubstring, account1.Nick)
			So(body, ShouldContainSubstring, "sent you 2 direct messages:")
		})

		Convey("Channel title should be rendered correctly when there are multiple recipients", func() {
			cp2 := models.NewChannelParticipant()
			cp2.Id = 1
			cp2.AccountId = account2.Id

			cs.Participants = append(cs.Participants, *cp2)

			ms2 := NewMessageSummary(account2.Nick, 0, "hoho", time.Now())
			cs.MessageSummaries = append(cs.MessageSummaries, ms2)
			Convey("when purpose is not set, account nicknames must be shown as title", func() {
				body, err := cs.Render()
				So(err, ShouldBeNil)
				So(body, ShouldContainSubstring, "hehe")
				So(body, ShouldContainSubstring, "123123")
				So(body, ShouldContainSubstring, account1.Nick)

				So(body, ShouldContainSubstring, "hoho")
				So(body, ShouldContainSubstring, "456456")
				So(body, ShouldContainSubstring, account2.Nick)

				title := fmt.Sprintf("%s & %s", account1.Nick, account2.Nick)
				So(body, ShouldContainSubstring, title)
			})

			Convey("when purpose is set it must be shown as title ", func() {
				cs.Purpose = "testing it"
				body, err := cs.Render()
				So(err, ShouldBeNil)
				So(body, ShouldContainSubstring, "hehe")
				So(body, ShouldContainSubstring, account1.Nick)

				So(body, ShouldContainSubstring, "hoho")
				So(body, ShouldContainSubstring, account2.Nick)

				So(body, ShouldContainSubstring, "testing it")

			})
		})

	})
}
