package main

import (
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func init() {
	registerAnalytic(numberOfReferrableEmails)
	registerAnalytic(numberOfInvitesSent)
	registerAnalytic(numberOfReferrals)
	registerAnalytic(numberOfReferralsToday)
}

func numberOfReferrableEmails() (string, int) {
	var identifier string = "number_of_referrable_emails"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Count()

		return err
	}

	mongodb.Run("jReferrableEmails", query)

	return identifier, count
}

func numberOfInvitesSent() (string, int) {
	var identifier string = "number_of_invites_sent"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{"invited": true}).Count()

		return err
	}

	mongodb.Run("jReferrableEmails", query)

	return identifier, count
}

func numberOfReferrals() (string, int) {
	var identifier string = "number_of_referrals"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Count()

		return err
	}

	mongodb.Run("jReferrals", query)

	return identifier, count
}

func numberOfReferralsToday() (string, int) {
	var identifier string = "number_of_referrals_today"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		var today = getTodayDate()
		var filter = bson.M{"createdAt": bson.M{"$gte": today}}

		count, err = c.Find(filter).Count()

		return err
	}

	mongodb.Run("jReferrals", query)

	return identifier, count
}
