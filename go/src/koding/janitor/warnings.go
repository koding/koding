package main

import (
	"time"

	"labix.org/v2/mgo/bson"
)

var (
	EmailLimitPerRun    = 10000
	DeleteVMLimitPerRun = 1000
)

// This is a general notification that user is inactive.
var FirstEmail = &Warning{
	Name: "Find users inactive for > 20 days, send email",

	Level: 1,

	Interval: 20,

	LimitPerRun: EmailLimitPerRun,

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(20),
		"inactive.warning": bson.M{"$exists": false},
	},

	Exempt: []Exempt{IsUserPaid, IsUserNotConfirmed},

	Action: SendEmail,
}

// This is a warning that user's vm will be deleted.
var SecondEmail = &Warning{
	Name: "Find users inactive for > 24 days, send email",

	Level: 2,

	Interval:                 24,
	IntervalSinceLastWarning: time.Hour * 24 * 4, // 4 days since last warning

	LimitPerRun: EmailLimitPerRun,

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(24),
		"inactive.warning": 1,
	},

	Exempt: []Exempt{IsTooSoon, IsUserPaid, IsUserNotConfirmed, IsUserVMsEmpty},

	Action: SendEmail,
}

// User hasn't come back, take action.
var ThirdDeleteVM = &Warning{
	Name: "Find users inactive for > 29 days, deleted ALL their vms",

	Level: 3,

	Interval:                 29,
	IntervalSinceLastWarning: time.Hour * 24 * 5, // 4 days since last warning

	LimitPerRun: EmailLimitPerRun,

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(29),
		"inactive.warning": 2,
	},

	Exempt: []Exempt{IsTooSoon, IsUserPaid, IsUserVMsEmpty},

	Action: DeleteVMs,
}
