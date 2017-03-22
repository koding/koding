package presence

import (
	mongomodels "koding/db/models"
	"math/rand"
	"socialapi/models"
	"socialapi/workers/common/tests"
	"testing"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestPresenceDailyOperations(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		groupName1 := models.RandomGroupName()
		Convey("With given presence data", t, func() {
			p1 := &models.PresenceDaily{
				AccountId: 1,
				GroupName: groupName1,
				// just to give some time between two records
				CreatedAt: time.Now().UTC().Add(-time.Millisecond * 100),
			}
			So(p1.Create(), ShouldBeNil)

			p2 := &models.PresenceDaily{
				AccountId: 1,
				GroupName: groupName1,
				CreatedAt: time.Now().UTC(),
			}
			So(p2.Create(), ShouldBeNil)

			Convey("getPresenceInfoFromDB should work properly", func() {
				pi, err := getPresenceInfoFromDB(&Ping{
					AccountID:     p2.AccountId,
					GroupName:     p2.GroupName,
					paymentStatus: string(mongomodels.SubStatusActive),
				})
				So(err, ShouldBeNil)
				So(pi, ShouldNotBeNil)
				// Why .Unix()? postgres omits after 6 decimal - due to our config.
				// Expected: '2016-09-21 13:44:50.695855774 +0000 UTC'
				// Actual:   '2016-09-21 13:44:50.695856 +0000 UTC'
				So(pi.CreatedAt.UTC().Unix(), ShouldEqual, p2.CreatedAt.UTC().Unix())

				pi2, err := getPresenceInfoFromDB(&Ping{
					AccountID:     p2.AccountId,
					GroupName:     "non_existent_group_name",
					paymentStatus: string(mongomodels.SubStatusActive),
				})
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)
				So(pi2, ShouldBeNil)

				pi3, err := getPresenceInfoFromDB(&Ping{
					AccountID:     rand.Int63(),
					GroupName:     groupName1,
					paymentStatus: string(mongomodels.SubStatusActive),
				})
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)
				So(pi3, ShouldBeNil)
			})
		})
	})
}

func TestPresenceDailyVerifyRecord(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		groupName1 := models.RandomGroupName()
		Convey("With given presence data", t, func() {

			Convey("should work properly with non existent data", func() {
				today := time.Now().UTC()
				ping := &Ping{
					AccountID:     1, // non existing user
					GroupName:     groupName1,
					CreatedAt:     today,
					paymentStatus: string(mongomodels.SubStatusActive),
				}

				So(verifyRecord(ping, today), ShouldBeNil)

				// we should be able to get it from db
				pd, err := getPresenceInfoFromDB(ping)
				So(err, ShouldBeNil)
				So(pd, ShouldNotBeNil)
			})

			Convey("should work properly with old existing data", func() {
				today := time.Now().UTC()
				prev := today.Add(-time.Minute)
				ping := &Ping{
					AccountID:     2, // non existing user
					GroupName:     groupName1,
					CreatedAt:     prev,
					paymentStatus: string(mongomodels.SubStatusActive),
				}
				So(insertPresenceInfoToDB(ping), ShouldBeNil)

				ping.CreatedAt = today
				err := verifyRecord(ping, today)
				So(err, ShouldBeNil)

				// we should be able to get it from db
				pd, err := getPresenceInfoFromDB(ping)
				So(err, ShouldBeNil)
				So(pd, ShouldNotBeNil)
			})

			Convey("should work properly with old deleted data", func() {
				today := time.Now().UTC()
				ping := &Ping{
					AccountID:     3, // non existing user
					GroupName:     groupName1,
					CreatedAt:     today,
					paymentStatus: string(mongomodels.SubStatusActive),
				}
				So(insertPresenceInfoToDB(ping), ShouldBeNil)

				err := (&models.PresenceDaily{}).ProcessByGroupName(groupName1)
				So(err, ShouldBeNil)

				// just to by pass the check in verify
				err = verifyRecord(ping, ping.CreatedAt.Add(-time.Second))
				So(err, ShouldBeNil)

				// we should be able to get it from db
				pd, err := getPresenceInfoFromDB(ping)
				So(err, ShouldBeNil)
				So(pd, ShouldNotBeNil)
			})
		})
	})
}

func TestPresenceDailyPing(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		groupName1 := models.RandomGroupName()
		Convey("With given presence data", t, func() {

			Convey("should work properly with non existent data", func() {
				today := time.Now().UTC()
				ping := &Ping{
					AccountID:     1, // non existing user
					GroupName:     groupName1,
					CreatedAt:     today,
					paymentStatus: string(mongomodels.SubStatusActive),
				}

				So(verifyRecord(ping, today), ShouldBeNil)

				// we should be able to get it from db
				pd, err := getPresenceInfoFromDB(ping)
				So(err, ShouldBeNil)
				So(pd, ShouldNotBeNil)
			})
		})
	})
}

func TestPresenceCancelledStatus(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("With given presence data", t, func() {
			account, _, groupSlug := models.CreateRandomGroupDataWithChecks()
			Convey("should work properly with invalid payment status", func() {
				today := time.Now().UTC()
				ping := &Ping{
					AccountID:     account.Id,
					GroupName:     groupSlug,
					CreatedAt:     today,
					paymentStatus: "invalid",
				}

				So(verifyRecord(ping, today), ShouldBeNil)

				// we should be able to get it from db
				pd, err := getPresenceInfoFromDB(ping)
				So(err, ShouldBeNil)
				So(pd, ShouldNotBeNil)
				So(pd.IsProcessed, ShouldBeTrue)
			})
		})
	})
}
