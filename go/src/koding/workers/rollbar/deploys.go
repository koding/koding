package main

import (
	"strconv"
	"time"

	"koding/db/models"

	"github.com/sent-hil/rollbar"
)

func importDeploysFromRollbarToDb() error {
	var latestDeploys, err = getLatestDeploysFromRollbar()
	if err != nil {
		return err
	}

	for _, i := range latestDeploys {
		var rollbarDeploy = &models.RollbarDeploy{
			DeployId:  i.Id,
			ProjectId: i.ProjectId,
			Alerted:   false,
		}

		// Normalize data according to our needs.
		var codeVersionInt, err = strconv.Atoi(i.Comment)
		if err != nil {
			log.Error("Invalid codeVersion value: %v for deploy: %v", i.Comment, i.Id)
			return err
		}

		rollbarDeploy.CodeVersion = codeVersionInt
		rollbarDeploy.StartTime = time.Unix(i.StartTime, 0)

		err = rollbarDeploy.UpsertByDeployId()
		if err != nil {
			log.Error("Saving/updating Deploy: %v", err)
			return err
		}
	}

	return nil
}

func getLatestDeploysFromRollbar() ([]rollbar.Deploy, error) {
	log.Debug("Fetching latest deploys from Rollbar")

	var deployService = rollbar.DeployService{rollbarClient}
	var deployResp, err = deployService.All()
	if err != nil {
		log.Error("Getting deploys: %v", err)
		return nil, err
	}

	return deployResp.Result.Deploys, err
}
