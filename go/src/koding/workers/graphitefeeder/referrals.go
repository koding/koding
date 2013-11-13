package main

import (
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"time"
)

func init() {
	registerAnalytic(numberOfReferrableEmails)
	registerAnalytic(numberOfInvitesSent)
	registerAnalytic(numberOfReferrals)
	registerAnalytic(numberOfReferralsToday)
	registerAnalytic(numberOfMembersFromReferrableEmailsToday)
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

func numberOfMembersFromReferrableEmailsToday() (string, int) {
	var identifier string = "number_of_members_from_referrable_emails_today"

	var results = make([]map[string]interface{}, 0)

	var currentYear, currentMonth, _ = time.Now().Date()

	var query = func(c *mgo.Collection) error {
		var thisMonth = time.Date(currentYear, currentMonth, 1, 0, 0, 0, 0, time.Local)
		var filter = bson.M{"invited": true, "createdAt": bson.M{"$gte": thisMonth}}

		var err = c.Find(filter).All(&results)

		return err
	}

	mongodb.Run("jReferrableEmails", query)

	var totalCount int
	for _, item := range results {
		var count int
		var err error
		var createdAtTime, ok = item["createdAt"].(time.Time)

		if !ok {
			log.Println("Unabled to get createdAtTime", item)
			continue
		}

		query = func(c *mgo.Collection) error {
			var filter = bson.M{
				"registeredAt": bson.M{"$gte": createdAtTime},
				"email":        item["email"].(string),
			}

			count, err = c.Find(filter).Count()
			totalCount += count

			return err
		}

		mongodb.Run("jUsers", query)
	}

	return identifier, totalCount
}
