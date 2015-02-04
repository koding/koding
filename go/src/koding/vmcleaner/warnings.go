package main

import (
	"github.com/koding/kite"

	"github.com/koding/kodingemail"
	"labix.org/v2/mgo/bson"
)

func initializeWarnings(kiteClient *kite.Client, email kodingemail.Client) []*Warning {
	controller := &Controller{Kite: kiteClient, Email: email}

	var FirstEmail = &Warning{
		Name: "Find users inactive for > 30 days, send email",

		Level: 1,

		Interval: 30,

		Select: bson.M{
			"lastLoginDate":    moreThanDaysQuery(30),
			"inactive.warning": bson.M{"$exists": false},
		},

		Exempt: []Exempt{IsUserPaid, IsUserBlocked},

		Action: controller.SendEmail,
	}

	var SecondEmail = &Warning{
		Name: "Find users inactive for > 45 days, send email",

		Level: 2,

		Interval: 45,

		Select: bson.M{
			"lastLoginDate":    moreThanDaysQuery(45),
			"inactive.warning": 1,
		},

		Exempt: []Exempt{IsUserPaid, IsUserBlocked, IsUserVMsEmpty},

		Action: controller.SendEmail,
	}

	var ThirdEmail = &Warning{
		Name: "Find users inactive for > 52 days, send email",

		Level: 3,

		Interval: 52,

		Select: bson.M{
			"lastLoginDate":    moreThanDaysQuery(52),
			"inactive.warning": 2,
		},

		Exempt: []Exempt{IsUserPaid, IsUserBlocked, IsUserVMsEmpty},

		Action: controller.SendEmail,
	}

	var FourthDeleteVM = &Warning{
		Name: "Find users inactive for > 60 days, delete ALL their vms",

		Level: 4,

		Interval: 60,

		Select: bson.M{
			"lastLoginDate":    moreThanDaysQuery(60),
			"inactive.warning": 3,
		},

		Exempt: []Exempt{IsUserPaid, IsUserVMsEmpty},

		Action: controller.DeleteVM,
	}

	return []*Warning{
		FirstEmail, SecondEmail, ThirdEmail, FourthDeleteVM,
	}
}
