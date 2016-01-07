package handler

import (
	kodingmodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"socialapi/config"
	"socialapi/models"
	"strconv"
	"testing"
	"time"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelUpdatedCalculateUnreadItemCount(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	groupName := models.RandomGroupName()

	Convey("while testing get account", t, func() {
		Convey("if cookie is not set, should return nil", func() {
			a := getAccount(&http.Request{}, models.Channel_KODING_NAME)
			So(a, ShouldNotBeNil)
			So(a.Id, ShouldBeZeroValue)
		})

		Convey("if cookie value is not set, should return nil", func() {
			req, _ := http.NewRequest("GET", "/", nil)

			expire := time.Now().AddDate(0, 0, 1)
			cookie := http.Cookie{
				Name:    "clientId",
				Value:   "",
				Path:    "/",
				Domain:  "localhost",
				Expires: expire,
			}

			req.AddCookie(&cookie)

			a := getAccount(req, models.Channel_KODING_NAME)
			So(a, ShouldNotBeNil)
			So(a.Id, ShouldBeZeroValue)
		})

		Convey("if session doesnt have username, should return nil", func() {
			ses, err := modelhelper.CreateSessionForAccount("", groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			req, _ := http.NewRequest("GET", "/", nil)
			expire := time.Now().AddDate(0, 0, 1)
			cookie := http.Cookie{
				Name:    "clientId",
				Value:   ses.ClientId,
				Path:    "/",
				Domain:  "localhost",
				Expires: expire,
			}

			req.AddCookie(&cookie)

			a := getAccount(req, models.Channel_KODING_NAME)
			So(a, ShouldNotBeNil)
			So(a.Id, ShouldBeZeroValue)
		})

		Convey("if session is valid, should return account", func() {
			acc, err := models.CreateAccountInBothDbs()
			So(err, ShouldBeNil)
			So(acc, ShouldNotBeNil)

			ses, err := modelhelper.CreateSessionForAccount(acc.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			req, _ := http.NewRequest("GET", "/", nil)
			expire := time.Now().AddDate(0, 0, 1)
			cookie := http.Cookie{
				Name:    "clientId",
				Value:   ses.ClientId,
				Path:    "/",
				Domain:  "localhost",
				Expires: expire,
			}

			req.AddCookie(&cookie)

			res := getAccount(req, models.Channel_KODING_NAME)
			So(res, ShouldNotBeNil)
			So(acc.Id, ShouldEqual, res.Id)
		})
	})

	Convey("while making sure account", t, func() {
		Convey("if account is not in postgres", func() {

			nick := models.RandomName()
			oldAcc := &kodingmodels.Account{
				Id: bson.NewObjectId(),
				Profile: kodingmodels.AccountProfile{
					Nickname: nick,
				},
			}
			err := modelhelper.CreateAccount(oldAcc)
			So(err, ShouldBeNil)

			oldUser := &kodingmodels.User{
				ObjectId:       bson.NewObjectId(),
				Password:       nick,
				Salt:           nick,
				Name:           nick,
				Email:          nick + "@koding.com",
				EmailFrequency: &kodingmodels.EmailFrequency{},
			}

			err = modelhelper.CreateUser(oldUser)
			So(err, ShouldBeNil)

			groupName := models.RandomGroupName()
			_, err = makeSureAccount(groupName, nick)
			So(err, ShouldBeNil)

			Convey("should create it in postgres", func() {
				a := models.NewAccount()
				err = a.ByNick(nick)
				So(err, ShouldBeNil)
				So(a.OldId, ShouldEqual, oldAcc.Id.Hex())

				Convey("should set socialAPI id in mongo", func() {
					oldAccFromDB, err := modelhelper.GetAccount(nick)
					So(err, ShouldBeNil)
					So(oldAccFromDB.SocialApiId, ShouldEqual, strconv.FormatInt(a.Id, 10))
				})
			})
		})

		Convey("if account is in postgres", func() {
			acc, err := models.CreateAccountInBothDbs()
			So(err, ShouldBeNil)
			So(acc, ShouldNotBeNil)

			groupName := models.RandomGroupName()

			_, err = makeSureAccount(groupName, acc.Nick)
			So(err, ShouldBeNil)

			Convey("should be in postgres", func() {
				a := models.NewAccount()
				err = a.ByNick(acc.Nick)
				So(err, ShouldBeNil)
				So(a.OldId, ShouldEqual, acc.OldId)

				Convey("should have socialAPI set", func() {
					oldAccFromDB, err := modelhelper.GetAccount(acc.Nick)
					So(err, ShouldBeNil)
					So(oldAccFromDB.SocialApiId, ShouldEqual, strconv.FormatInt(a.Id, 10))
				})
			})
		})
	})

	Convey("while making sure group membership", t, func() {
		Convey("if account is not not a member", func() {
			account := models.CreateAccountWithTest()
			requester := models.CreateAccountWithTest()
			groupChannel := models.CreateTypedPublicChannelWithTest(account.Id, models.Channel_TYPE_GROUP)

			err := makeSureMembership(groupChannel, requester.Id)
			So(err, ShouldBeNil)

			Convey("should add as participant", func() {
				status, err := groupChannel.IsParticipant(requester.Id)
				So(err, ShouldBeNil)
				So(status, ShouldBeTrue)

				Convey("if account is a member", func() {
					err := makeSureMembership(groupChannel, requester.Id)
					So(err, ShouldBeNil)

					Convey("should be a participant", func() {
						status, err := groupChannel.IsParticipant(requester.Id)
						So(err, ShouldBeNil)
						So(status, ShouldBeTrue)
					})
				})
			})

		})
	})
}
