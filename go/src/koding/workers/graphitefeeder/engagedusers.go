package main

import (
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

	var result map[string]interface{}
	var possibleEngagedUsers = map[string]bool{}

	var iterFn = func(iter *mgo.Iter) error {
		for iter.Next(&result) {
			var username = result["username"].(string)
			possibleEngagedUsers[username] = true
		}

		return nil
	}

	var err = mongodb.Iter("jSessionHistories", iterQuery, iterFn)
	if err != nil {
		log.Error("Closing mongo iter: %v", err)
	}

	log.Debug("Possible EngagedUsers count: %v", len(possibleEngagedUsers))

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
				"username":  bson.M{"$in": smallerSet},
				"createdAt": bson.M{"$gt": middleOfMonth},
			})

			return query
		}

		var secondIterFn = func(iter *mgo.Iter) error {
			var secondResult map[string]interface{}
			for iter.Next(&secondResult) {
				var username = secondResult["username"].(string)
				engagedUsers[username] = true
			}

			return nil
		}

		err = mongodb.Iter("jSessionHistories", secondIterQuery, secondIterFn)
		if err != nil {
			log.Error("Closing mongo iter: %v", err)
			break
		}

		if len(possibleEngagedUsernames) < 100 {
			break
		}

		possibleEngagedUsernames = possibleEngagedUsernames[endPos:]
	}

	log.Debug("EngagedUsers count: %v", len(engagedUsers))

	var engagedUsernames = []string{}
	for username, _ := range engagedUsers {
		engagedUsernames = append(engagedUsernames, username)
	}

	var engagedUsernamesLength = len(engagedUsernames)

	var session = mongodb.Mongo.GetSession()
	defer session.Close()

	return identifier, engagedUsernamesLength
}
