package models

import (
	"socialapi/workers/common/tests"
	"testing"
	"time"

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
				})
			})
		})
	})
}
