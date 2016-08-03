package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/httputil"
	"net/http"
	"sync"
	"time"

	"gopkg.in/mgo.v2/bson"
)

const myPermissionsAndRolesPath = "/-/my/permissionsAndRoles"

var defClient = httputil.NewClient(&httputil.ClientConfig{
	DialTimeout:           30 * time.Second,
	RoundTripTimeout:      30 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ResponseHeaderTimeout: 30 * time.Second,
})

type EnvData struct {
	Own           []*MachineAndWorkspaces `json:"own"`
	Shared        []*MachineAndWorkspaces `json:"shared"`
	Collaboration []*MachineAndWorkspaces `json:"collaboration"`
}

type MachineAndWorkspaces struct {
	Machine    *modelhelper.MachineContainer     `json:"machine"`
	Workspaces []*modelhelper.WorkspaceContainer `json:"workspaces"`
}

func fetchEnvData(userInfo *UserInfo, user *LoggedInUser, wg *sync.WaitGroup) {
	defer wg.Done()
	envData := getEnvData(userInfo)
	user.Set("EnvData", envData)
}

func fetchRolesAndPermissions(userInfo *UserInfo, user *LoggedInUser, wg *sync.WaitGroup) {
	defer wg.Done()
	path := fmt.Sprintf("%s%s", conf.SocialApi.CustomDomain.Local, myPermissionsAndRolesPath)
	envData, err := doGetRequest(path, userInfo.ClientId)
	if err != nil {
		Log.Error(err.Error())
	}

	user.Set("Roles", envData["roles"])
	user.Set("Permissions", envData["permissions"])
}

func fetchUserMachines(userInfo *UserInfo, user *LoggedInUser, wg *sync.WaitGroup) {
	defer wg.Done()
	userMachines := getUserMachines(userInfo.UserId, userInfo.Group)
	user.Set("UserMachines", userMachines)
}

func getEnvData(userInfo *UserInfo) *EnvData {
	var collab = []*MachineAndWorkspaces{}
	var userId = userInfo.UserId

	socialApiId := userInfo.SocialApiId
	if socialApiId != "" {
		collab = getCollab(userInfo)
	}

	return &EnvData{
		Own:           getOwn(userId, userInfo.Group),
		Shared:        getShared(userId, userInfo.Group),
		Collaboration: collab,
	}
}

func getUserMachines(userId bson.ObjectId, group *models.Group) []*modelhelper.MachineContainer {
	machines, err := modelhelper.GetGroupMachines(userId, group)
	if err != nil {
		Log.Error(fmt.Sprintf("Error fetching machines for: %s %s", userId, err))
		return nil
	}

	return machines
}

func getOwn(userId bson.ObjectId, group *models.Group) []*MachineAndWorkspaces {
	ownMachines, err := modelhelper.GetOwnGroupMachines(userId, group)
	if err != nil {
		Log.Error(fmt.Sprintf("Error fetching machines for: %s %s", userId, err))
		return nil
	}

	return getWorkspacesForEachMachine(ownMachines)
}

func getShared(userId bson.ObjectId, group *models.Group) []*MachineAndWorkspaces {
	sharedMachines, err := modelhelper.GetSharedGroupMachines(userId, group)
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

	rawResponse, err := fetchSocialItem(url, userInfo)
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

func doGetRequest(endpoint, clientId string) (map[string]interface{}, error) {
	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	req.AddCookie(&http.Cookie{
		Name:  "clientId",
		Value: clientId,
	})

	resp, err := defClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("err: status code (%d)", resp.StatusCode)
	}

	var res map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return nil, err
	}

	return res, nil
}
