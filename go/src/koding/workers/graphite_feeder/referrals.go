package main

import (
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func init() {
	registerAnalytic(numberOfReferrals)
}

func numberOfReferrals() (string, int) {
	var identifier string = "number_of_referrals"
	var count int
	var err error
	var query = func(c *mgo.Collection) error {
		count, err = c.Find(nil).Count()

		return err
	}

	mongodb.Run("jReferrals", query)

	return identifier, count
}
