package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestExempt(t *testing.T) {
	Convey("It should exempt if user is Koding employee", t, func() {
		acc1 := &models.Account{
			Id:          bson.NewObjectId(),
			Profile:     models.AccountProfile{Nickname: "indianajones"},
			GlobalFlags: []string{models.AccountFlagStaff},
		}
		err := modeltesthelper.CreateAccount(acc1)
		So(err, ShouldBeNil)

		defer modeltesthelper.DeleteUsersByUsername(acc1.Profile.Nickname)

		isEmployee, err := isKodingEmployee(acc1.Profile.Nickname)
		So(err, ShouldBeNil)
		So(isEmployee, ShouldBeTrue)

		acc2 := &models.Account{
			Id:      bson.NewObjectId(),
			Profile: models.AccountProfile{Nickname: "genghiskhan"},
		}
		err = modeltesthelper.CreateAccount(acc2)
		So(err, ShouldBeNil)

		defer modeltesthelper.DeleteUsersByUsername(acc2.Profile.Nickname)

		isEmployee, err = isKodingEmployee(acc2.Profile.Nickname)
		So(err, ShouldBeNil)
		So(isEmployee, ShouldBeFalse)
	})
}
