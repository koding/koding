package main

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo/bson"
)

type EnvData struct {
	Own           []*MachineAndWorkspaces `json:"own"`
	Shared        []*MachineAndWorkspaces `json:"shared"`
	Collaboration []*MachineAndWorkspaces `json:"collaboration"`
}

type MachineAndWorkspaces struct {
	Machine    *modelhelper.MachineContainer     `json:"machine"`
	Workspaces []*modelhelper.WorkspaceContainer `json:"workspaces"`
}

func fetchEnvData(userInfo *UserInfo, outputter *Outputter) {
	envData := getEnvData(userInfo)
	outputter.OnItem <- &Item{Name: "EnvData", Data: envData}
}

func getEnvData(userInfo *UserInfo) *EnvData {
	var collab = []*MachineAndWorkspaces{}
	var userId = userInfo.UserId

	socialApiId := userInfo.SocialApiId
	if socialApiId != "" {
		collab = getCollab(userInfo)
	}

	return &EnvData{
		Own:           getOwn(userId),
		Shared:        getShared(userId),
		Collaboration: collab,
	}
}

func getOwn(userId bson.ObjectId) []*MachineAndWorkspaces {
	ownMachines, err := modelhelper.GetOwnMachines(userId)
	if err != nil {
		Log.Error(fmt.Sprintf("Error fetching machines for: %s %s", userId, err))
		return nil
	}

	return getWorkspacesForEachMachine(ownMachines)
}

func getShared(userId bson.ObjectId) []*MachineAndWorkspaces {
	sharedMachines, err := modelhelper.GetSharedMachines(userId)
	if err != nil {
		Log.Error(fmt.Sprintf(
			"Error fetching shared machines for: %s %s", userId, err))
		return nil
	}

	return getWorkspacesForEachMachine(sharedMachines)
}

func getCollab(userInfo *UserInfo) []*MachineAndWorkspaces {
	machines, err := modelhelper.GetCollabMachines(userInfo.UserId, userInfo.Group)
	if err != nil {
		Log.Error(fmt.Sprintf(
			"Error fetching collaboration machines for: %s %s", userInfo.UserId, err))
		return nil
	}

	channelIds, err := getCollabChannels(userInfo)
	if err != nil {
		Log.Error(fmt.Sprintf(
			"Error fetching collaboration channelIds for: %s %s %s",
			userInfo.UserId, userInfo.SocialApiId, err))
		return nil
	}

	workspaces, err := modelhelper.GetWorkspacesContainersByChannelIds(channelIds)
	if err != nil {
		Log.Error(fmt.Sprintf(
			"Error fetching workspaces channelIds for: %s %s %s",
			userInfo.UserId, channelIds, err))
		return nil
	}

	mwByMachineUids := map[string]*MachineAndWorkspaces{}
	for _, machine := range machines {
		mwByMachineUids[machine.Uid] = &MachineAndWorkspaces{
			Machine: machine, Workspaces: []*modelhelper.WorkspaceContainer{},
		}
	}

	for _, workspace := range workspaces {
		mw, ok := mwByMachineUids[workspace.MachineUID]
		if ok {
			mw.Workspaces = append(mw.Workspaces, workspace)
		}
	}

	mws := []*MachineAndWorkspaces{}
	for _, machineWorkspace := range mwByMachineUids {
		mws = append(mws, machineWorkspace)
	}

	return mws
}

func getWorkspacesForEachMachine(machines []*modelhelper.MachineContainer) []*MachineAndWorkspaces {
	mws := []*MachineAndWorkspaces{}

	for _, mContainer := range machines {
		machineAndWorkspace := &MachineAndWorkspaces{Machine: mContainer}
		machine := mContainer.Machine

		workspaces, err := modelhelper.GetWorkspacesContainers(machine)
		if err == nil {
			machineAndWorkspace.Workspaces = workspaces
		} else {
			Log.Error(fmt.Sprintf(
				"Error fetching workspaces for: %s %s", machine.ObjectId, err))
		}

		mws = append(mws, machineAndWorkspace)
	}

	return mws
}

func getCollabChannels(userInfo *UserInfo) ([]string, error) {
	path := "%v/privatechannel/list?accountId=%[2]s"
	url := buildUrl(path, userInfo.SocialApiId, "type=collaboration", fmt.Sprintf("groupName=%s", userInfo.Group.Slug))

	rawResponse, err := fetchSocialItem(url)
	if err != nil {
		return nil, err
	}

	response, ok := rawResponse.([]interface{})
	if !ok {
		return nil, errors.New("error unmarshalling repsonse")
	}

	channelIds := []string{}
	for _, single := range response {
		raw, ok := single.(map[string]interface{})
		if !ok {
			continue
		}

		channel, ok := raw["channel"].(map[string]interface{})
		if !ok {
			continue
		}

		id, ok := channel["id"].(string)
		if !ok {
			continue
		}

		channelIds = append(channelIds, id)
	}

	return channelIds, nil
}
