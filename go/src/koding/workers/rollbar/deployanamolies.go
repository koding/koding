package main

import (
	"koding/db/models"
	"koding/tools/config"
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

	err = alert(latestDeploy, latestDeployItems)
	if err != nil {
		log.Error("Posting alerting: %v", err)
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
