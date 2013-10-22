package main

import (
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"time"
)

func init() {
	registerAnalytic(numberOfAccounts)
	registerAnalytic(numberOfUsersWhoLinkedOauth)
	registerAnalytic(numberOfInvitesSent)
	registerAnalytic(numberOfUsersWhoJoinedToday)
}

func numberOfAccounts() (string, int) {
	var identifier string = "number_of_accounts"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Count()

		return err
	}

	mongodb.Run("jAccounts", query)

	return identifier, count
}

func numberOfUsersWhoLinkedOauth() (string, int) {
	var identifier string = "number_of_users_who_linked_oauth"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{"foreignAuth": bson.M{"$exists": true}}).Count()

		return err
	}

	mongodb.Run("jUsers", query)

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

func numberOfUsersWhoJoinedToday() (string, int) {
	var identifier string = "number_of_users_who_joined_today"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		year, month, day := time.Now().Date()
		var today = time.Date(year, month, day, 0, 0, 0, 0, time.Local)
		var filter = bson.M{"meta.createdAt": bson.M{"$gt": today}}

		count, err = c.Find(filter).Count()

		return err
	}

	mongodb.Run("jAccounts", query)

	return identifier, count
}
