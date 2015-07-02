package main

import (
	"time"

	"labix.org/v2/mgo/bson"
)

var VMDeletionWarning1 = &Warning{
	ID: "vmDeletionWarning-1",

	Description: "Find users inactive for > 20 days, send email",

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(20)},
		bson.M{"inactive.warning": bson.M{"$exists": false}},
	},

	ExemptCheckers: []*ExemptChecker{
		IsUserPaid, IsUserNotConfirmed, IsUserVMsEmpty, IsUserKodingEmployee,
	},

	Action: SendEmail,
}

var VMDeletionWarning2 = &Warning{
	ID: "vmDeletionWarning-2",

	Description: "Find users inactive for > 24 days, send email",

	PreviousWarning: VMDeletionWarning1,

	IntervalSinceLastWarning: time.Hour * 24 * 4, // 4 days since last warning

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(24)},
		bson.M{"inactive.warning": VMDeletionWarning1.ID},
	},

	ExemptCheckers: []*ExemptChecker{
		IsTooSoon, IsUserPaid, IsUserNotConfirmed, IsUserVMsEmpty, IsUserKodingEmployee,
	},

	Action: SendEmail,
}

var DeleteInactiveUserVM = &Warning{
	ID: "deleteInactiveUserVm",

	Description: "Find users inactive for > 29 days, deleted ALL their vms",

	PreviousWarning: VMDeletionWarning2,

	IntervalSinceLastWarning: time.Hour * 24 * 4, // 4 days since last warning

	Select: []bson.M{
		bson.M{"lastLoginDate": moreThanDaysQuery(29)},
		bson.M{"inactive.warning": VMDeletionWarning2.ID},
	},

	ExemptCheckers: []*ExemptChecker{
		IsTooSoon, IsUserPaid, IsUserVMsEmpty, IsUserKodingEmployee,
	},

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
