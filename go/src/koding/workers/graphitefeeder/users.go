package main

import (
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func init() {
	registerAnalytic(numberOfAccounts)
	registerAnalytic(numberOfUsersWhoLinkedOauth)
	registerAnalytic(numberOfUsersWhoLinkedOauthGithub)
	registerAnalytic(numberOfReferrableEmails)
	registerAnalytic(numberOfInvitesSent)
	registerAnalytic(numberOfUsersWhoJoinedToday)
	registerAnalytic(numberOfGuestAccountsCreatedToday)
	registerAnalytic(numberOfUsersWhoDeletedTheirAccount)
	registerAnalytic(numberOfUsersWhoDidASocialActivityToday)
	// commenting this out till persistence worker is fixed
	//registerAnalytic(numberOfUsersWhoAreOnline)
	registerAnalytic(numberOfUsersWhoLoggedInToday)
	registerAnalytic(numberOfGuestAccounts)
}

func numberOfAccounts() (string, int) {
	var identifier string = "number_of_accounts"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		var filter = bson.M{"type": "registered"}
		count, err = c.Find(filter).Count()

		return err
	}

	mongo.Run("jAccounts", query)

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

	mongo.Run("jUsers", query)

	return identifier, count
}

func numberOfUsersWhoLinkedOauthGithub() (string, int) {
	var identifier string = "number_of_users_who_linked_github"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{"foreignAuth.github": bson.M{"$exists": true}}).Count()

		return err
	}

	mongo.Run("jUsers", query)

	return identifier, count
}

func numberOfUsersWhoJoinedToday() (string, int) {
	var identifier string = "number_of_users_who_joined_today"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		var today = getTodayDate()
		var filter = bson.M{"meta.createdAt": bson.M{"$gte": today}, "type": "registered"}

		count, err = c.Find(filter).Count()

		return err
	}

	mongo.Run("jAccounts", query)

	return identifier, count
}

func numberOfGuestAccountsCreatedToday() (string, int) {
	var identifier string = "number_of_guest_accounts_created_today"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		var today = getTodayDate()
		var filter = bson.M{"meta.createdAt": bson.M{"$gte": today}, "type": "unregistered"}

		count, err = c.Find(filter).Count()

		return err
	}

	mongo.Run("jAccounts", query)

	return identifier, count
}

func numberOfUsersWhoDeletedTheirAccount() (string, int) {
	var identifier string = "number_of_users_who_deleted_their_account"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{"status": "deleted"}).Count()

		return err
	}

	mongo.Run("jUsers", query)

	return identifier, count
}

func numberOfUsersWhoDidASocialActivityToday() (string, int) {
	var identifier string = "number_of_users_who_did_a_social_activity_today"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		var today = getTodayDate()
		var filter = bson.M{"meta.modifiedAt": bson.M{"$gte": today}}

		count, err = c.Find(filter).Count()

		return err
	}

	mongo.Run("jAccounts", query)

	return identifier, count
}

func numberOfUsersWhoAreOnline() (string, int) {
	var identifier string = "number_of_users_who_are_online"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{"onlineStatus": "online"}).Count()

		return err
	}

	mongo.Run("jAccounts", query)

	return identifier, count
}

func numberOfUsersWhoLoggedInToday() (string, int) {
	var identifier string = "number_of_users_who_logged_in_today"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		var today = getTodayDate()
		var filter = bson.M{"lastLoginDate": bson.M{"$gte": today}}

		count, err = c.Find(filter).Count()

		return err
	}

	mongo.Run("jUsers", query)

	return identifier, count
}

func numberOfGuestAccounts() (string, int) {
	var identifier string = "number_of_guest_accounts"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		var filter = bson.M{"type": "unregistered"}

		count, err = c.Find(filter).Count()

		return err
	}

	mongo.Run("jAccounts", query)

	return identifier, count
}
