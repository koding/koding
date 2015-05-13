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

var ComebackEmail = &Warning{
	ID: "comebackEmail",

	Description: "Find users inactive for > 20 days, send email",

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(20)},
		bson.M{"inactive.warning": bson.M{"$exists": false}},
	},

	ExemptCheckers: []*ExemptChecker{IsUserPaid, IsUserNotConfirmed},

	Action: SendEmail,
}

var VMDeletionEmail = &Warning{
	ID: "vmDeletionEmail",

	Description: "Find users inactive for > 24 days, send email",

	PreviousWarning: ComebackEmail,

	IntervalSinceLastWarning: time.Hour * 24 * 4, // 4 days since last warning

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(24)},
		bson.M{"inactive.warning": ComebackEmail.ID},
	},

	ExemptCheckers: []*ExemptChecker{
		IsTooSoon, IsUserPaid, IsUserNotConfirmed, IsUserVMsEmpty,
	},

	Action: SendEmail,
}

var DeleteInactiveUserVM = &Warning{
	ID: "deleteInactiveUserVm",

	Description: "Find users inactive for > 29 days, deleted ALL their vms",

	PreviousWarning: VMDeletionEmail,

	IntervalSinceLastWarning: time.Hour * 24 * 4, // 4 days since last warning

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(29)},
		bson.M{"inactive.warning": VMDeletionEmail.ID},
	},

	ExemptCheckers: []*ExemptChecker{IsTooSoon, IsUserPaid, IsUserVMsEmpty},

	Action: DeleteVMs,
}

var DeleteBlockedUserVM = &Warning{
	ID: "deleteBlockedUserVm",

	Description: "Find blocked users inactive > 14 days, delete ALL their vms",

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(14)},
		bson.M{"inactive.warning": bson.M{"$exists": false}},
		bson.M{"status": "blocked"},
	},

	ExemptCheckers: []*ExemptChecker{IsUserVMsEmpty},

	Action: DeleteVMs,
}
