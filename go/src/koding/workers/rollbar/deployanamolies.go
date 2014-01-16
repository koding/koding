package main

import (
	"fmt"
	"github.com/sent-hil/slack"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	slackToken    = "xoxp-2155583316-2155760004-2158149487-a72cf4"
	slackChannel  = "C024LG80K"
	slackUsername = "Senthil"
)

func checkForDeployAnamolies() error {
	var latestDeploy, err = getLatestDeploy()
	if err != nil {
		log.Error("Getting latest deploy from db: %v", err)
	}

	if latestDeploy.Alerted == true {
		log.Debug("Already alerted slack of latest deploy, returning")
		return nil
	}

	var latestDeployVersion = latestDeploy.CodeVersion
	latestDeployItems, err := getErrorsForDeploy(latestDeployVersion)
	if err != nil {
		log.Error("Getting items for latest deploy from db: %v", err)
	}

	if len(latestDeployItems) == 0 {
		log.Debug("0 new errors in deploy: %v, returning", latestDeployVersion)
		return nil
	}

	err = postToSlack(latestDeployItems)
	if err != nil {
		return err
	}

	err = updateDeploy(latestDeploy)

	return err
}

func getLatestDeploy() (*SaveableDeploy, error) {
	var foundDeploy SaveableDeploy
	var findQuery = func(c *mgo.Collection) error {
		return c.Find(nil).Sort("-deployId").One(&foundDeploy)
	}

	var err = mongodb.Run("deploys", findQuery)

	log.Debug("Id of latest deploy: %v", foundDeploy.CodeVersion)

	return &foundDeploy, err
}

func getErrorsForDeploy(deployId int) ([]SaveableItem, error) {
	var foundItems []SaveableItem
	var findQuery = func(c *mgo.Collection) error {
		return c.Find(bson.M{"codeVersion": deployId}).All(&foundItems)
	}

	var err = mongodb.Run("rollbarItems", findQuery)

	log.Debug("Found %v entries for deploy: %v", len(foundItems), deployId)

	return foundItems, err
}

func postToSlack(latestDeployItems []SaveableItem) error {
	var text = fmt.Sprintf("%v new errors happened after deploy: %v", len(latestDeployItems), latestDeployItems[0].CodeVersion)

	var slackClient = slack.NewClient(slackToken)
	var messageService = slack.NewMessageService(slackClient)
	var message = &slack.Message{
		Channel:  slackChannel,
		Username: slackUsername,
		Text:     text,
	}

	_, err := messageService.Post(message)
	if err != nil {
		return err
	}

	return err
}

func updateDeploy(latestDeploy *SaveableDeploy) error {
	log.Debug("Updating deploy with id: %v of alert status", latestDeploy.CodeVersion)

	var query = func(c *mgo.Collection) error {
		var findQuery = bson.M{"_id": latestDeploy.Id}
		var updateQuery = bson.M{"$set": bson.M{"alerted": true}}

		return c.Update(findQuery, updateQuery)
	}

	var err = mongodb.Run("deploys", query)

	return err
}
