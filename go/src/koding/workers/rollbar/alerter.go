package main

import (
	"fmt"

	"koding/db/models"

	"github.com/sent-hil/slack"
)

func alert(latestDeploy *models.RollbarDeploy, latestDeployItems []*models.RollbarItem) error {
	if latestDeploy.Alerted == true {
		log.Debug("Already alerted slack of latest deploy, returning")
		return nil
	}

	var err = postToSlack(latestDeployItems)

	return err
}

func postToSlack(latestDeployItems []*models.RollbarItem) error {
	var text = fmt.Sprintf("%v new errors happened after deploy: %v",
		len(latestDeployItems), latestDeployItems[0].CodeVersion)

	log.Debug("Alerting slack of latest deploy with text:\n %v", text)

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
