package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"

	"labix.org/v2/mgo/bson"

	"github.com/koding/redis"
	. "github.com/smartystreets/goconvey/convey"
)

func TestExempt(t *testing.T) {
	Convey("It should exempt if user is in list of exempt users", t, func() {
		redisConn, err := redis.NewRedisSession(&redis.RedisConf{Server: conf.Redis.URL})
		So(err, ShouldBeNil)

		defer redisConn.Close()

		acc1 := &models.Account{
			Id:      bson.NewObjectId(),
			Profile: models.AccountProfile{Nickname: "indianajones"},
		}
		err = modeltesthelper.CreateAccount(acc1)
		So(err, ShouldBeNil)

		defer modeltesthelper.DeleteUsersByUsername(acc1.Profile.Nickname)

		isExempt, err := isInExemptList(redisConn, acc1.Profile.Nickname)
		So(err, ShouldBeNil)
		So(isExempt, ShouldBeFalse)

		_, err = redisConn.AddSetMembers(ExemptUsersKey, acc1.Profile.Nickname)
		So(err, ShouldBeNil)

		isExempt, err = isInExemptList(redisConn, acc1.Profile.Nickname)
		So(err, ShouldBeNil)
		So(isExempt, ShouldBeTrue)

		defer redisConn.Del(ExemptUsersKey)
	})
}
