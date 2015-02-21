package main

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo/bson"
)

type EnvData struct {
	Own           []*MachineAndWorkspaces
	Shared        []*MachineAndWorkspaces
	Collaboration []*MachineAndWorkspaces
}

type MachineAndWorkspaces struct {
	Machine    models.Machine
	Workspaces []*models.Workspace
}

func getEnvData(user *models.User) *EnvData {
	userId := user.ObjectId

	return &EnvData{
		Own:           getOwn(userId),
		Shared:        getShared(userId),
		Collaboration: getCollab(user),
	}
}

func getOwn(userId bson.ObjectId) []*MachineAndWorkspaces {
	ownMachines, err := modelhelper.GetOwnMachines(userId)
	if err != nil {
		return nil
	}

	return getWorkspacesForEachMachine(ownMachines)
}

func getShared(userId bson.ObjectId) []*MachineAndWorkspaces {
	sharedMachines, err := modelhelper.GetSharedMachines(userId)
	if err != nil {
		return nil
	}

	return getWorkspacesForEachMachine(sharedMachines)
}

func getCollab(user *models.User) []*MachineAndWorkspaces {
	_, err := modelhelper.GetCollabMachines(user.ObjectId)
	if err != nil {
		return nil
	}

	_, err = getCollabChannels(user.Name)
	if err != nil {
		return nil
	}

	return nil
}

func getWorkspacesForEachMachine(machines []models.Machine) []*MachineAndWorkspaces {
	mws := []*MachineAndWorkspaces{}

	for _, machine := range machines {
		machineAndWorkspace := &MachineAndWorkspaces{Machine: machine}

		workspaces, err := modelhelper.GetWorkspacesForMachine(machine.ObjectId)
		if err != nil {
			machineAndWorkspace.Workspaces = workspaces
		}

		mws = append(mws, machineAndWorkspace)
	}

	return mws
}

func getCollabChannels(username string) ([]string, error) {
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	path := "/privatechannel/list?accountId="
	url := buildUrl(path, account.Id.Hex(), "type=collaboration")

	raw, err := fetchSocialItem(url)
	if err != nil {
		return nil, err
	}

	response, ok := raw.([]string)
	if !ok {
		return nil, errors.New("error unmarshalling repsonse")
	}

	return response, nil
}
