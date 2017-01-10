package models

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/request"
	"socialapi/workers/common/tests"
	"testing"
	"time"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/bongo"
	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestPresenceDailyOperations(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		groupName1 := RandomGroupName()
		groupName2 := RandomGroupName()
		Convey("With given presence data", t, func() {
			p1 := &PresenceDaily{
				AccountId: 1,
				GroupName: groupName1,
				CreatedAt: time.Now().UTC(),
			}
			So(p1.Create(), ShouldBeNil)

			p2 := &PresenceDaily{
				AccountId: 2,
				GroupName: groupName1,
				CreatedAt: time.Now().UTC(),
			}
			So(p2.Create(), ShouldBeNil)

			p2_1 := &PresenceDaily{
				AccountId: 2,
				GroupName: groupName1,
				CreatedAt: time.Now().UTC(),
			}
			So(p2_1.Create(), ShouldBeNil)

			p3 := &PresenceDaily{
				AccountId: 3,
				GroupName: groupName2,
				CreatedAt: time.Now().UTC(),
			}
			So(p3.Create(), ShouldBeNil)

			Convey("CountDistinctByGroupName should work properly", func() {
				c1, err := (&PresenceDaily{}).CountDistinctByGroupName(groupName1)
				So(err, ShouldBeNil)
				So(c1, ShouldNotBeNil)

				c2, err := (&PresenceDaily{}).CountDistinctByGroupName(groupName2)
				So(err, ShouldBeNil)
				So(c2, ShouldNotBeNil)

				// we created 2 accounts in groupName1
				So(c1, ShouldEqual, 2)
				// we created 1 accounts in groupName1
				So(c2, ShouldEqual, 1)

				Convey("ProcessByGroupName should work properly", func() {
					err = (&PresenceDaily{}).ProcessByGroupName(groupName1)
					So(err, ShouldBeNil)

					c3, err := (&PresenceDaily{}).CountDistinctByGroupName(groupName1)
					So(err, ShouldBeNil)
					So(c3, ShouldNotBeNil)

					c4, err := (&PresenceDaily{}).CountDistinctByGroupName(groupName2)
					So(err, ShouldBeNil)
					So(c4, ShouldNotBeNil)

					// we deleted all the accounts in groupName1
					So(c3, ShouldEqual, 0)
					// groupName2's count should stay same
					So(c4, ShouldEqual, c2)

					Convey("CountDistinctProcessedByGroupName should work properly", func() {
						c5, err := (&PresenceDaily{}).CountDistinctProcessedByGroupName(groupName1)
						So(err, ShouldBeNil)
						So(c5, ShouldNotBeNil)
						// we created 2 accounts in groupName1
						So(c5, ShouldEqual, 2)
					})
				})
			})
		})
	})
}

func TestPresenceDailyFetchActiveAccounts(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("With given presence data", t, func() {
			acc1, _, groupName := CreateRandomGroupDataWithChecks()

			gr, err := modelhelper.GetGroup(groupName)
			tests.ResultedWithNoErrorCheck(gr, err)
			err = modelhelper.MakeAdmin(bson.ObjectIdHex(acc1.OldId), gr.Id)
			So(err, ShouldBeNil)

			p1 := &PresenceDaily{
				AccountId: acc1.Id,
				GroupName: groupName,
				CreatedAt: time.Now().UTC(),
			}
			So(p1.Create(), ShouldBeNil)
			ses, err := modelhelper.FetchOrCreateSession(acc1.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			for i := 0; i < 5; i++ {
				// create accounts
				acc2 := CreateAccountInBothDbsWithCheck()

				// add them to presence
				p1 := &PresenceDaily{
					AccountId: acc2.Id,
					GroupName: groupName,
					CreatedAt: time.Now().UTC(),
				}
				So(p1.Create(), ShouldBeNil)
			}

			Convey("FetchActiveAccounts should not work properly if query is nil", func() {
				query := request.NewQuery()
				c1, err := (&PresenceDaily{}).FetchActiveAccounts(query)
				So(err, ShouldNotBeNil)
				So(c1, ShouldBeNil)

				Convey("FetchActiveAccounts should work properly", func() {
					query := request.NewQuery().SetDefaults()
					query.GroupName = groupName
					c1, err := (&PresenceDaily{}).FetchActiveAccounts(query)
					So(err, ShouldBeNil)
					So(c1, ShouldNotBeNil)
				})

				Convey("Pagination skip should work properly", func() {
					query := request.NewQuery().SetDefaults()
					query.GroupName = groupName
					query.Skip = 20
					c1, err := (&PresenceDaily{}).FetchActiveAccounts(query)
					So(err, ShouldNotBeNil)
					So(err, ShouldEqual, bongo.RecordNotFound)
					So(c1, ShouldBeNil)

					Convey("Pagination limit should work properly", func() {
						query := request.NewQuery().SetDefaults()
						query.GroupName = groupName
						query.Limit = 4
						c1, err := (&PresenceDaily{}).FetchActiveAccounts(query)
						So(err, ShouldBeNil)
						So(c1, ShouldNotBeNil)
						So(len(c1.Accounts), ShouldEqual, 4)
					})
				})
			})
		})
	})
}
