package main

import (
	"time"

	"labix.org/v2/mgo/bson"
)

// Sane defaults to prevent spamming the system.
var (
	EmailLimitPerRun    = 5000
	DeleteVMLimitPerRun = 5000
)

// This is a general notification that user is inactive.
var FirstEmail = &Warning{
	Name: "Find users inactive for > 20 days, send email",

	Level: 1,

	LimitPerRun: EmailLimitPerRun,

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(20)},
		bson.M{"inactive.warning": bson.M{"$exists": false}},
	},

	Exempt: []Exempt{IsUserPaid, IsUserNotConfirmed},

	Action: SendEmail,
}

// This is a warning that user's vm will be deleted.
var SecondEmail = &Warning{
	Name: "Find users inactive for > 24 days, send email",

	Level: 2,

	IntervalSinceLastWarning: time.Hour * 24 * 4, // 4 days since last warning

	LimitPerRun: EmailLimitPerRun,

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(24)},
		bson.M{"inactive.warning": 1},
	},

	Exempt: []Exempt{IsTooSoon, IsUserPaid, IsUserNotConfirmed, IsUserVMsEmpty},

	Action: SendEmail,
}

// User hasn't come back, take action.
var ThirdDeleteVM = &Warning{
	Name: "Find users inactive for > 29 days, deleted ALL their vms",

	Level: 3,

	IntervalSinceLastWarning: time.Hour * 24 * 5, // 4 days since last warning

	LimitPerRun: EmailLimitPerRun,

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(29)},
		bson.M{"inactive.warning": 2},
	},

	Exempt: []Exempt{IsTooSoon, IsUserPaid, IsUserVMsEmpty},

	Action: DeleteVMs,
}

// User hasn't come back, take action.
var FourthDeleteBlockedUserVm = &Warning{
	Name: "Find blocked users, delete ALL their vms",

	Level: 4,

	IntervalSinceLastWarning: time.Hour * 24 * 7, // 4 days since last warning

	LimitPerRun: EmailLimitPerRun,

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(5)},
		bson.M{"status": "blocked"},
	},

	Exempt: []Exempt{IsTooSoon, IsUserVMsEmpty},

	Action: DeleteVMs,
}
