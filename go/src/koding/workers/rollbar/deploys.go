package main

import (
	"github.com/sent-hil/rollbar"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strconv"
	"time"
)

type SaveableDeploy struct {
	DeployId    int       `bson:"deployId"`
	ProjectId   int       `bson:"projectId"`
	StartTime   time.Time `bson:"startTime"`
	CodeVersion int       `bson:"codeVersion"`
	Alerted     bool
}

func curryDeploysFromRollbarToDb() error {
	var latestDeploys, err = getLatestDeploysFromRollbar()
	if err != nil {
		return err
	}

	for _, i := range latestDeploys {
		var saveableDeploy = &SaveableDeploy{
			DeployId:  i.Id,
			ProjectId: i.ProjectId,
			Alerted:   false,
		}

		// Normalize data according to our needs.
		var codeVersionInt, _ = strconv.Atoi(i.Comment)
		saveableDeploy.CodeVersion = codeVersionInt

		saveableDeploy.StartTime = time.Unix(i.StartTime, 0)

		err = saveUniqueDeploy(saveableDeploy)
		if err != nil {
			log.Error("Saving/updating Deploy: %v", err)
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
	}

	return deployResp.Result.Deploys, err
}

func saveUniqueDeploy(s *SaveableDeploy) error {
	var foundDeploy SaveableDeploy
	var findQuery = func(c *mgo.Collection) error {
		return c.Find(bson.M{"deployId": s.DeployId}).One(&foundDeploy)
	}

	var secondErr error
	var err = mongodb.Run("deploys", findQuery)
	if err != nil {
		secondErr = saveDeploy(s)
	}

	return secondErr
}

func saveDeploy(s *SaveableDeploy) error {
	log.Debug("Depoly with id: %v not found, saving", s.DeployId)

	var query = func(c *mgo.Collection) error {
		return c.Insert(s)
	}

	var err = mongodb.Run("deploys", query)

	return err
}
