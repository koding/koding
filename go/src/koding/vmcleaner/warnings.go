package main

import (
	"time"

	"labix.org/v2/mgo/bson"
)

var FirstEmail = &Warning{
	Name: "Find users inactive for > 30 days, send email",

	Level: 1,

	Interval: 30,

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(30),
		"inactive.warning": bson.M{"$exists": false},
	},

	Exempt: []Exempt{IsUserPaid, IsUserBlocked},

	Action: SendEmail,
}

var SecondEmail = &Warning{
	Name: "Find users inactive for > 45 days, send email",

	Level: 2,

	Interval:                 45,
	IntervalSinceLastWarning: time.Hour * 24 * 15, // 15 days since last warning

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(45),
		"inactive.warning": 1,
	},

	Exempt: []Exempt{IsUserPaid, IsUserBlocked, IsUserVMsEmpty},

	Action: SendEmail,
}

var ThirdEmail = &Warning{
	Name: "Find users inactive for > 52 days, send email",

	Level: 3,

	Interval:                 52,
	IntervalSinceLastWarning: time.Hour * 24 * 7, // 7 days since last warning

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(52),
		"inactive.warning": 2,
	},

	Exempt: []Exempt{IsUserPaid, IsUserBlocked, IsUserVMsEmpty},

	Action: SendEmail,
}

var FourthDeleteVM = &Warning{
	Name: "Find users inactive for > 60 days, delete ALL their vms",

	Level: 4,

	Interval:                 60,
	IntervalSinceLastWarning: time.Hour * 24 * 8, // 8 days since last warning

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(60),
		"inactive.warning": 3,
	},

	Exempt: []Exempt{IsUserPaid, IsUserVMsEmpty},

	Action: DeleteVM,
}
