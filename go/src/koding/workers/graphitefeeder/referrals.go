package main

import (
	"koding/tools/log"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func init() {
	registerAnalytic(numberOfReferrableEmails)
	registerAnalytic(numberOfInvitesSent)
	registerAnalytic(numberOfReferrals)
	registerAnalytic(numberOfReferralsToday)
	registerAnalytic(numberOfMembersFromReferrableEmailsToday)
	registerAnalytic(numberOfMembersFromReferrableEmailsThisMonth)
	registerAnalytic(numberOfMembersFromReferrableEmails)
}

func numberOfReferrableEmails() (string, int) {
	var identifier string = "number_of_referrable_emails"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Count()

		return err
	}

	mongo.Run("jReferrableEmails", query)

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

	mongo.Run("jReferrableEmails", query)

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

	mongo.Run("jReferrals", query)

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

	mongo.Run("jReferrals", query)

	return identifier, count
}

func numberOfMembersFromReferrableEmails() (string, int) {
	var identifier = "number_of_members_from_referrable_emails"
	var unixEpochDate = time.Date(1970, time.January, 1, 0, 0, 0, 0, currentTimeLocation)

	return identifier, numberOfMembersFromReferrableEmailsByTime(unixEpochDate)
}

func numberOfMembersFromReferrableEmailsThisMonth() (string, int) {
	var identifier = "number_of_members_from_referrable_emails_this_month"
	var currentYear, currentMonth, _ = time.Now().Date()
	var currentMonthDate = time.Date(currentYear, currentMonth, 1, 0, 0, 0, 0, currentTimeLocation)

	return identifier, numberOfMembersFromReferrableEmailsByTime(currentMonthDate)
}

func numberOfMembersFromReferrableEmailsToday() (string, int) {
	var identifier = "number_of_members_from_referrable_emails_today"
	var today = getTodayDate()

	return identifier, numberOfMembersFromReferrableEmailsByTime(today)
}

func numberOfMembersFromReferrableEmailsByTime(greaterThanDate time.Time) int {
	var results = make([]map[string]interface{}, 0)

	var query = func(c *mgo.Collection) error {
		var filter = bson.M{
			"invited":   true,
			"createdAt": bson.M{"$gte": greaterThanDate},
		}

		var err = c.Find(filter).All(&results)

		return err
	}

	mongo.Run("jReferrableEmails", query)

	var totalCount int
	for _, item := range results {
		var count int
		var err error
		var createdAtTime, ok = item["createdAt"].(time.Time)

		if !ok {
			log.Info("Unabled to get createdAtTime: %v", item)
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

		mongo.Run("jUsers", query)
	}

	return totalCount
}
