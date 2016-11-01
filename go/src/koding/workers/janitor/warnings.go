package main

import (
	"socialapi/config"
	"time"

	"gopkg.in/mgo.v2/bson"
)

var VMDeletionWarning1 = &Warning{
	ID: "vmDeletionWarning-1",

	Description: "Find users inactive for > 20 days, send email",

	Select: []bson.M{
		{"lastLoginDate": dayRangeQuery(20, DefaultRangeForQuery)},
		{"inactive.warning": bson.M{"$exists": false}},
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
		{"lastLoginDate": dayRangeQuery(24, DefaultRangeForQuery)},
		{"inactive.warning": VMDeletionWarning1.ID},
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
		{"lastLoginDate": dayRangeQuery(29, DefaultRangeForQuery)},
		{"inactive.warning": VMDeletionWarning2.ID},
	},

	ExemptCheckers: []*ExemptChecker{
		IsTooSoon, IsUserPaid, IsUserVMsEmpty, IsUserKodingEmployee,
	},

	Action: DeleteVMs,

	Throttled: true,
}

func newDeleteInactiveUsersWarning(conf *config.Config) *Warning {
	unregisterURL := conf.Protocol + "//" + conf.Hostname + "/" + "-/Unregister"

	// this will cause deletion of 17495 accounts, will update this query once
	// we delete all the account till last month ~1.2M
	t, err := time.Parse("Jan 2 15:04:05 -0700 MST 2006", "Oct 1 00:00:00 -0000 MST 2013")
	if err != nil {
		panic(err.Error())
	}

	return &Warning{
		ID: "deleteInactiveUsers",

		Description: "Find users inactive for > 45 days, deleted ALL of them!",

		Select: []bson.M{
			{"lastLoginDate": bson.M{"$lt": t}},
			{"status": bson.M{"$nin": []string{"deleted"}}},
		},

		ExemptCheckers: []*ExemptChecker{
			IsUserPaid, HasMultipleMemberships, IsUserKodingEmployee,
		},

		Action: newDeleteUserFunc(unregisterURL),

		Throttled: true,
	}
}

var DeleteBlockedUserVM = &Warning{
	ID: "deleteBlockedUserVm",

	Description: "Find blocked users inactive > 14 days, delete ALL their vms",

	Select: []bson.M{
		{"lastLoginDate": dayRangeQuery(14, DefaultRangeForQuery)},
		{"inactive.warning": bson.M{"$exists": false}},
		{"status": "blocked"},
	},

	ExemptCheckers: []*ExemptChecker{IsUserVMsEmpty},

	Action: DeleteVMs,

	Throttled: true,
}
