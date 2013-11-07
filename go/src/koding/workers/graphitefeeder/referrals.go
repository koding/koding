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
	registerAnalytic(numberOfReferralsWhoBecameMembersToday)
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

func numberOfReferralsWhoBecameMembersToday() (string, int) {
	var identifier string = "number_of_referrals_who_became_members_today"

	var results = make([]map[string]interface{}, 0)

	var query = func(c *mgo.Collection) error {
		var november = time.Date(2013, time.November, 1, 0, 0, 0, 0, time.Local)
		var filter = bson.M{"invited": true, "createdAt": bson.M{"$gte": november}}

		log.Println(">>> november query", filter)

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
