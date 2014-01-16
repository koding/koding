package main

import (
	"fmt"

	"koding/db/models"
	"koding/db/mongodb"
	"koding/tools/config"

	"github.com/sent-hil/slack"
	"labix.org/v2/mgo"
)

var (
	slackToken   = config.Current.Slack.Token
	slackChannel = config.Current.Slack.Channel
)

func checkForDeployAnamolies() error {
	var latestDeploy = &models.RollbarDeploy{}
	var err = latestDeploy.GetLatestDeploy()
	if err != nil {
		log.Error("Getting latest deploy from db: %v", err)
		return err
	}

	if latestDeploy.Alerted == true {
		log.Debug("Already alerted slack of latest deploy, returning")
		return nil
	}

	var latestDeployVersion = latestDeploy.CodeVersion
	latestDeployItems, err := getErrorsForDeploy(latestDeployVersion)
	if err != nil {
		log.Error("Getting items for latest deploy from db: %v", err)
		return err
	}

	if len(latestDeployItems) == 0 {
		log.Debug("0 new errors in deploy: %v, returning", latestDeployVersion)
		return nil
	}

	err = postToSlack(latestDeployItems)
	if err != nil {
		log.Error("Posting to slack: %v", err)
		return err
	}

	err = latestDeploy.UpdateAlertStatus()

	return err
}

func getErrorsForDeploy(deployId int) ([]*models.RollbarItem, error) {
	var rollbarItem = &models.RollbarItem{CodeVersion: deployId}
	var foundItems, err = rollbarItem.FindByCodeVersion()

	return foundItems, err
}

func postToSlack(latestDeployItems []*models.RollbarItem) error {
	var text = fmt.Sprintf("%v new errors happened after deploy: %v",
		len(latestDeployItems), latestDeployItems[0].CodeVersion)

	var slackClient = slack.NewClient(slackToken)
	var messageService = slack.NewMessageService(slackClient)
	var message = &slack.Message{
		Channel: slackChannel,
		Text:    text,
	}

	_, err := messageService.Post(message)
	if err != nil {
		return err
	}

	return err
}
