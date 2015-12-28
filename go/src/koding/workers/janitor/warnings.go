package main

import (
	"time"

	"gopkg.in/mgo.v2/bson"
)

var VMDeletionWarning1 = &Warning{
	ID: "vmDeletionWarning-1",

	Description: "Find users inactive for > 20 days, send email",

	Select: []bson.M{
		bson.M{"lastLoginDate": dayRangeQuery(20, DefaultRangeForQuery)},
		bson.M{"inactive.warning": bson.M{"$exists": false}},
	},

	ExemptCheckers: []*ExemptChecker{
		IsUserPaid, IsUserVMsEmpty, IsUserKodingEmployee,
	},

	Action: SendEmail,

	Throttled: false,
}

var VMDeletionWarning2 = &Warning{
	ID: "vmDeletionWarning-2",

	Description: "Find users inactive for > 24 days, send email",

	PreviousWarning: VMDeletionWarning1,

	IntervalSinceLastWarning: time.Hour * 24 * 4, // 4 days since last warning

	Select: []bson.M{
		bson.M{"lastLoginDate": dayRangeQuery(24, DefaultRangeForQuery)},
		bson.M{"inactive.warning": VMDeletionWarning1.ID},
	},

	ExemptCheckers: []*ExemptChecker{
		IsTooSoon, IsUserPaid, IsUserVMsEmpty, IsUserKodingEmployee,
	},

	Action: SendEmail,

	Throttled: false,
}

var DeleteInactiveUserVM = &Warning{
	ID: "deleteInactiveUserVm",

	Description: "Find users inactive for > 29 days, deleted ALL their vms",

	PreviousWarning: VMDeletionWarning2,

	IntervalSinceLastWarning: time.Hour * 24 * 4, // 4 days since last warning

	Select: []bson.M{
		bson.M{"lastLoginDate": dayRangeQuery(29, DefaultRangeForQuery)},
		bson.M{"inactive.warning": VMDeletionWarning2.ID},
	},

	ExemptCheckers: []*ExemptChecker{
		IsTooSoon, IsUserPaid, IsUserVMsEmpty, IsUserKodingEmployee,
	},

	Action: DeleteVMs,

	Throttled: true,
}

var DeleteBlockedUserVM = &Warning{
	ID: "deleteBlockedUserVm",

	Description: "Find blocked users inactive > 14 days, delete ALL their vms",

	Select: []bson.M{
		bson.M{"lastLoginDate": dayRangeQuery(14, DefaultRangeForQuery)},
		bson.M{"inactive.warning": bson.M{"$exists": false}},
		bson.M{"status": "blocked"},
	},

	ExemptCheckers: []*ExemptChecker{IsUserVMsEmpty},

	Action: DeleteVMs,

	Throttled: true,
}
