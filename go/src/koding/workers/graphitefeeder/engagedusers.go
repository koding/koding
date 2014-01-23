package main

import (
	"fmt"
	"time"

	"koding/db/mongodb"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func init() {
	registerAnalytic(numberOfTwoWeekEngagedUsers)
}

func numberOfTwoWeekEngagedUsers() (string, int) {
	var identifier string = "number_of_two_week_engaged_users"
	var year, month, _ = time.Now().Date()
	var startDateOfMonth = time.Date(year, month, 1, 0, 0, 0, 0, currentTimeLocation)

	// 14 isn't always the middle of the month, but it's easier to assume for now
	var middleOfMonth = time.Date(year, month, 14, 0, 0, 0, 0, currentTimeLocation)

	var iterQuery = func(c *mgo.Collection) *mgo.Query {
		var query = c.Find(bson.M{
			"createdAt": bson.M{"$gte": startDateOfMonth, "$lte": middleOfMonth},
		})

		return query
	}

	var possibleEngagedUsers = map[string]bool{}

	var err = mongodb.Iter("jSessionHistories", iterQuery, func(result map[string]interface{}) error {
		var username = result["username"].(string)
		possibleEngagedUsers[username] = true

		return nil
	})

	if err != nil {
		fmt.Println(err)
	}

	fmt.Println("count of possibleEngagedUsers", len(possibleEngagedUsers))

	var possibleEngagedUsernames = []string{}
	for username, _ := range possibleEngagedUsers {
		possibleEngagedUsernames = append(possibleEngagedUsernames, username)
	}

	//----------------------------------------------------------
	// Second Query
	//----------------------------------------------------------

	var secondIterQuery = func(c *mgo.Collection) *mgo.Query {
		var query = c.Find(bson.M{
			"username":  bson.M{"$in": possibleEngagedUsernames},
			"createdAt": bson.M{"$gt": middleOfMonth},
		})

		return query
	}

	var engagedUsers = map[string]bool{}

	err = mongodb.Iter("jSessionHistories", secondIterQuery, func(result map[string]interface{}) error {
		var username = result["username"].(string)
		engagedUsers[username] = true

		return nil
	})

	if err != nil {
		fmt.Println(err)
	}

	fmt.Println("count of engagedUsers", len(engagedUsers))

	var engagedUsernames = []string{}
	for username, _ := range engagedUsers {
		engagedUsernames = append(engagedUsernames, username)
	}

	var engagedUsernamesLength = len(engagedUsernames)

	return identifier, engagedUsernamesLength
}
