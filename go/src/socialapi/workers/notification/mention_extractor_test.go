package notification

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	socialapimodels "socialapi/models"
	"socialapi/workers/common/tests"
	"testing"
	"time"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
	"gopkg.in/mgo.v2/bson"
)

func TestUnifyAliases(t *testing.T) {
	testData := []struct {
		definition string
		usernames  []string
		expected   []string
	}{
		{
			"should remove aliases",
			[]string{"team", "all"},
			[]string{"all"},
		},
		{
			"should return same usernames",
			[]string{"foo", "bar", "zaar"},
			[]string{"foo", "bar", "zaar"},
		},
		{
			"should remove duplicates",
			[]string{"admins", "admins", "ff"},
			[]string{"admins", "ff"},
		},
		{
			"should remove specific ones if have a general one",
			[]string{"admins", "admins", "team"},
			[]string{"all"},
		},
		{
			"should reduce to global alias",
			[]string{"team", "all", "group"},
			[]string{"all"},
		},
		{
			"should keep team",
			[]string{"channel", "bar", "admins", "team"},
			[]string{"all"},
		},
	}

	for _, test := range testData {
		responses := unifyAliases(test.usernames)
		exists := false
		for _, response := range responses {
			for _, exc := range test.expected {
				if exc == response {
					exists = true
					break
				}
			}
		}

		if !exists {
			t.Fatalf("expected to exist but doesnt got: %+v for: %+v", responses, test.definition)
		}

		if len(test.expected) != len(responses) {
			t.Fatalf("%s, %s. expected: %+v, got: %+v", test.definition, "expected lengths are not same", test.expected, responses)
		}
	}
}

func TestNormalize(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		appConfig := config.MustRead(r.Conf.Path)
		modelhelper.Initialize(appConfig.Mongo)
		defer modelhelper.Close()

		Convey("while normalizing the usernames to their original nicks", t, func() {
			adminAccount, groupChannel, _ := socialapimodels.CreateRandomGroupDataWithChecks()
			account1 := socialapimodels.CreateAccountInBothDbsWithCheck()
			account2 := socialapimodels.CreateAccountInBothDbsWithCheck()
			account3 := socialapimodels.CreateAccountInBothDbsWithCheck()

			_, err := groupChannel.AddParticipant(account1.Id)
			So(err, ShouldBeNil)
			_, err = groupChannel.AddParticipant(account2.Id)
			So(err, ShouldBeNil)
			_, err = groupChannel.AddParticipant(account3.Id)
			So(err, ShouldBeNil)

			topicChan := socialapimodels.CreateTypedGroupedChannelWithTest(account1.Id, socialapimodels.Channel_TYPE_TOPIC, groupChannel.GroupName)

			Convey("@all should return all the members of the posted channel", func() {
				body := "hi @all i am really excited to join this team!"
				cm := socialapimodels.CreateMessageWithBody(groupChannel.Id, adminAccount.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 3)

				Convey("poster should not be in the mention list", func() {
					So(socialapimodels.IsIn(adminAccount.Nick, usernames...), ShouldBeFalse)
				})
			})

			Convey("multiple @all should return all the members of the channel", func() {
				body := "hi @all i am really excited to join this team! @team @all"
				cm := socialapimodels.CreateMessageWithBody(groupChannel.Id, adminAccount.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 3)
			})

			Convey("@all + @channel should return all the members of the channel", func() {
				body := "hi @all i am really excited to join this team! @all"
				cm := socialapimodels.CreateMessageWithBody(groupChannel.Id, adminAccount.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 3)
			})

			Convey("@team should return all the members of the team in a non-group channel", func() {
				_, err := topicChan.AddParticipant(adminAccount.Id)
				So(err, ShouldBeNil)
				_, err = topicChan.AddParticipant(account2.Id)
				So(err, ShouldBeNil)
				_, err = topicChan.AddParticipant(account3.Id)
				So(err, ShouldBeNil)

				body := "hi @team i am really excited to join this chan!"
				cm := socialapimodels.CreateMessageWithBody(topicChan.Id, adminAccount.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 2)
				So(usernames, ShouldContain, account2.Nick)
				So(usernames, ShouldContain, account3.Nick)
				So(usernames, ShouldNotContain, adminAccount.Nick) // poster should not be in the list
			})

			// UnifyAliases
			Convey("@all + any multiple username should return all the members of the team", func() {
				body := "hi @all i am really excited to join this team! how are you @" + account3.Nick + " @" + account3.Nick
				cm := socialapimodels.CreateMessageWithBody(groupChannel.Id, adminAccount.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 3)
				So(usernames, ShouldContain, account1.Nick)
				So(usernames, ShouldContain, account2.Nick)
				So(usernames, ShouldContain, account3.Nick)
				So(usernames, ShouldNotContain, adminAccount.Nick) // poster should not be in the list
			})

			// UnifyUsernames
			Convey("any multiple username should return one of them", func() {
				body := "hi, i am really excited to join this team! how are you @" + account3.Nick + " @" + account3.Nick
				cm := socialapimodels.CreateMessageWithBody(groupChannel.Id, adminAccount.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 1)
				So(usernames, ShouldContain, account3.Nick)
			})

			// ConvertAliases
			Convey("@channel should return all the members of the channel", func() {

				body := "hi @channel"
				cm := socialapimodels.CreateMessageWithBody(topicChan.Id, account1.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				Convey("if channel doesnt have any members", func() {
					Convey("should return 0 username", func() {
						usernames, err := NewMentionExtractor(cm, r.Log).Do()
						So(err, ShouldBeNil)
						So(len(usernames), ShouldEqual, 0)
					})
				})

				Convey("if channel have member", func() {
					Convey("should return them", func() {
						_, err := topicChan.AddParticipant(account2.Id)
						So(err, ShouldBeNil)

						usernames, err := NewMentionExtractor(cm, r.Log).Do()
						So(err, ShouldBeNil)
						So(len(usernames), ShouldEqual, 1)
						So(usernames[0], ShouldEqual, account2.Nick)
					})
				})
			})

			Convey("@admins should return all the admins of the team", func() {
				group, err := modelhelper.GetGroup(groupChannel.GroupName)
				So(err, ShouldBeNil)

				err = makeAdmin(bson.ObjectIdHex(account1.OldId), group.Id)
				So(err, ShouldBeNil)

				body := "hi @admins make me mod plzz"
				cm := socialapimodels.CreateMessageWithBody(topicChan.Id, account2.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				Convey("if topic channel doesnt have any admin members", func() {
					Convey("should return 0 username", func() {
						usernames, err := NewMentionExtractor(cm, r.Log).Do()
						So(err, ShouldBeNil)
						So(len(usernames), ShouldEqual, 0)
					})
				})
				Convey("if channel have member", func() {
					Convey("should return them", func() {
						_, err := topicChan.AddParticipant(account1.Id)
						So(err, ShouldBeNil)

						usernames, err := NewMentionExtractor(cm, r.Log).Do()
						So(err, ShouldBeNil)
						So(len(usernames), ShouldEqual, 1)
						So(usernames[0], ShouldEqual, account1.Nick)
					})
				})

				Convey("adding another user to mention list should work", func() {
					_, err := topicChan.AddParticipant(account1.Id)
					So(err, ShouldBeNil)

					_, err = topicChan.AddParticipant(account3.Id)
					So(err, ShouldBeNil)

					body := fmt.Sprintf("hi @%s do you know who are in @admins ? i believe @%s is in", account2.Nick, account3.Nick)
					cm := socialapimodels.CreateMessageWithBody(topicChan.Id, account2.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

					usernames, err := NewMentionExtractor(cm, r.Log).Do()
					So(err, ShouldBeNil)
					So(len(usernames), ShouldEqual, 2)
					So(usernames, ShouldContain, account1.Nick)
					So(usernames, ShouldContain, account3.Nick)

				})
			})

			// FilterParticipants
			Convey("non members of public channel should not be in mention list", func() {
				_, err := topicChan.AddParticipant(adminAccount.Id)
				So(err, ShouldBeNil)

				_, err = topicChan.AddParticipant(account1.Id)
				So(err, ShouldBeNil)

				body := fmt.Sprintf("hi @%s i heard that @%s is not in this channel? but can get the notification? no way right?", account1.Nick, account2.Nick)

				cm := socialapimodels.CreateMessageWithBody(topicChan.Id, adminAccount.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 1)
				So(usernames, ShouldContain, account1.Nick)
				So(usernames, ShouldNotContain, account2.Nick)
			})

			Convey("non members of team should not be in mention list", func() {
				nonmember := socialapimodels.CreateAccountInBothDbsWithCheck()

				body := "hi @" + nonmember.Nick
				cm := socialapimodels.CreateMessageWithBody(topicChan.Id, account2.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 0)
			})

			Convey("non existing members of team should not be in mention list", func() {
				body := "hi @nonmember how are things with your @girlfriend?"
				cm := socialapimodels.CreateMessageWithBody(topicChan.Id, account2.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 0)
			})

			Convey("non members of a private channel should not be in mention list", func() {
				nonmember := socialapimodels.CreateAccountInBothDbsWithCheck()
				_, err := groupChannel.AddParticipant(nonmember.Id)
				So(err, ShouldBeNil)

				pmChan := socialapimodels.CreateTypedGroupedChannelWithTest(account1.Id, socialapimodels.Channel_TYPE_PRIVATE_MESSAGE, groupChannel.GroupName)
				_, err = pmChan.AddParticipant(account1.Id)
				So(err, ShouldBeNil)
				_, err = pmChan.AddParticipant(account2.Id)
				So(err, ShouldBeNil)

				body := "hi @" + nonmember.Nick + " and @" + account1.Nick
				cm := socialapimodels.CreateMessageWithBody(pmChan.Id, account2.Id, socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 1)
				So(usernames, ShouldContain, account1.Nick)
			})

			Convey("aliases should not work for koding group", func() {
				account := socialapimodels.CreateAccountWithTest()
				groupChannel := socialapimodels.CreateTypedGroupedChannelWithTest(account.Id, socialapimodels.Channel_TYPE_GROUP, socialapimodels.Channel_KODING_NAME)
				_, err := groupChannel.AddParticipant(account.Id)
				So(err, ShouldBeNil)

				// add more members
				account1 := socialapimodels.CreateAccountInBothDbsWithCheck()
				account2 := socialapimodels.CreateAccountInBothDbsWithCheck()
				account3 := socialapimodels.CreateAccountInBothDbsWithCheck()

				_, err = groupChannel.AddParticipant(account1.Id)
				So(err, ShouldBeNil)
				_, err = groupChannel.AddParticipant(account2.Id)
				So(err, ShouldBeNil)
				_, err = groupChannel.AddParticipant(account3.Id)
				So(err, ShouldBeNil)

				body := "hi @all"

				cm := socialapimodels.CreateMessageWithBody(groupChannel.Id, account.Id, socialapimodels.ChannelMessage_TYPE_POST, body)

				usernames, err := NewMentionExtractor(cm, r.Log).Do()
				So(err, ShouldBeNil)
				So(len(usernames), ShouldEqual, 1)
				So(usernames, ShouldContain, "all")
			})

		})
	})
}

func makeAdmin(accountId, groupId bson.ObjectId) error {
	r := &mongomodels.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   accountId,
		TargetName: "JAccount",
		SourceId:   groupId,
		SourceName: "JGroup",
		As:         "admin",
		TimeStamp:  time.Now().UTC(),
	}

	return modelhelper.AddRelationship(r)
}
