package emailmodels

import (
	"socialapi/models"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestEmailSummaryTitle(t *testing.T) {
	Convey("While preparing email summary title", t, func() {
		Convey("Should show direct message content, when there are only direct messages", func() {
			cs1 := &ChannelSummary{}
			cp1 := models.ChannelParticipant{}
			cp1.AccountId = 1
			cs1.Participants = []models.ChannelParticipant{cp1}
			cs1.UnreadCount = 2

			channels := []*ChannelSummary{cs1}
			es := NewEmailSummary(channels)
			title := es.BuildTitle()
			So(title, ShouldEqual, "You have 2 direct messages.")
		})

		Convey("Should show group message content, when there are only group messages", func() {
			cs1 := &ChannelSummary{}
			cp1 := models.ChannelParticipant{}
			cp1.AccountId = 1
			cp2 := models.ChannelParticipant{}
			cp2.AccountId = 2

			cs1.Participants = []models.ChannelParticipant{cp1, cp2}
			cs1.UnreadCount = 2

			channels := []*ChannelSummary{cs1}
			es := NewEmailSummary(channels)
			title := es.BuildTitle()
			So(title, ShouldEqual, "You have 2 new messages in 1 group conversation.")
		})

		Convey("Should show both direc message and group message content, when both exist", func() {
			cs1 := &ChannelSummary{}
			cp1 := models.ChannelParticipant{}
			cp1.AccountId = 1
			cp2 := models.ChannelParticipant{}
			cp2.AccountId = 2

			cs1.Participants = []models.ChannelParticipant{cp1, cp2}
			cs1.UnreadCount = 2

			cs2 := &ChannelSummary{}
			cs2.Participants = []models.ChannelParticipant{cp1}
			cp1.AccountId = 1
			cs2.UnreadCount = 3

			channels := []*ChannelSummary{cs1, cs2}
			es := NewEmailSummary(channels)
			title := es.BuildTitle()
			So(title, ShouldEqual, "You have 3 direct messages, and there are 2 new messages in 1 group conversation.")
		})

	})
}
