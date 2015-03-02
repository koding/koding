package tests

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/mailparse/models"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMailParse(t *testing.T) {
	r := runner.New("test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	Convey("while sending mail", t, func() {

		Convey("reponse should be success", func() {
			acc, err := socialapimodels.CreateAccountInBothDbs()
			So(err, ShouldBeNil)

			c := socialapimodels.CreateChannelWithTest(acc.Id)
			socialapimodels.AddParticipants(c.Id, acc.Id)

			cm := socialapimodels.CreateMessage(c.Id, acc.Id, socialapimodels.ChannelMessage_TYPE_POST)
			So(cm, ShouldNotBeNil)

			mongoUser, err := modelhelper.GetUser(acc.Nick)
			So(err, ShouldBeNil)

			p := &models.Mail{
				From:              mongoUser.Email,
				OriginalRecipient: fmt.Sprintf("reply+messageid.%d@inbound.koding.com", c.Id),
				MailboxHash:       fmt.Sprintf("messageid.%d", cm.Id),
				TextBody:          "Its an example of text message",
				StrippedTextReply: "This one is reply message",
			}

			res, err := rest.MailParse(p)
			So(err, ShouldBeNil)
			So(res, ShouldNotBeNil)
		})
	})
}
