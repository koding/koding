package main

import "labix.org/v2/mgo/bson"

var FirstEmail = &Warning{
	Name: "Find users inactive for > 45 days, send email",

	Level: 1,

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(45),
		"inactive.warning": bson.M{"$exists": false},
	},

	Exempt: []Exempt{IsUserPaid, IsUserBlocked},

	Action: SendEmail,
}

var SecondEmail = &Warning{
	Name: "Find users inactive for > 52 days, send email again",

	Level: 2,

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(52),
		"inactive.warning": 1,
	},

	Exempt: []Exempt{IsUserPaid, IsUserBlocked},

	Action: SendEmail,
}

var ThirdDeleteVM = &Warning{
	Name: "Find users inactive for > 60 days, delete ALL their vms",

	Level: 3,

	Select: bson.M{
		"lastLoginDate":    moreThanDaysQuery(60),
		"inactive.warning": 2,
	},

	Exempt: []Exempt{IsUserPaid},

	Action: DeleteVM,
}
