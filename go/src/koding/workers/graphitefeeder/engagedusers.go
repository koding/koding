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
	var middleOfMonth = time.Date(year, month, 15, 0, 0, 0, 0, currentTimeLocation)

	var iterQuery = func(c *mgo.Collection) *mgo.Query {
		var query = c.Find(bson.M{
			"createdAt": bson.M{"$gte": startDateOfMonth, "$lte": middleOfMonth},
		})

		return query
	}

	var iter = mongodb.Iter("jSessionHistories", iterQuery)
	var result map[string]interface{}
	var possibleEngagedUsers = map[string]bool{}

	for iter.Next(&result) {
		var username = result["username"].(string)
		possibleEngagedUsers[username] = true
	}

	var err = mongodb.IterClose(iter)
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

	var engagedUsers = map[string]bool{}
	var startPos = 0
	var endPos = startPos + 100

	for {
		if len(possibleEngagedUsernames) < 100 {
			endPos = len(possibleEngagedUsernames)
		}

		var smallerSet = possibleEngagedUsernames[startPos:endPos]
		var secondIterQuery = func(c *mgo.Collection) *mgo.Query {
			var query = c.Find(bson.M{
				"username":  bson.M{"$in": possibleEngagedUsernames},
				"createdAt": bson.M{"$gt": smallerSet},
			})

			return query
		}

		var secondIter = mongodb.Iter("jSessionHistories", secondIterQuery)
		var secondResult map[string]interface{}

		for secondIter.Next(&secondResult) {
			var username = result["username"].(string)
			engagedUsers[username] = true
		}

		err = mongodb.IterClose(secondIter)
		if err != nil {
			fmt.Println(err)
			break
		}

		if len(possibleEngagedUsernames) < 100 {
			break
		}

		startPos += 100
		endPos += 100
		possibleEngagedUsernames = possibleEngagedUsernames[endPos:]
	}

	fmt.Println("count of engagedUsers", len(engagedUsers))

	var engagedUsernames = []string{}
	for username, _ := range engagedUsers {
		engagedUsernames = append(engagedUsernames, username)
	}

	var engagedUsernamesLength = len(engagedUsernames)

	var session = mongodb.Mongo.GetSession()
	defer session.Close()

	return identifier, engagedUsernamesLength
}
