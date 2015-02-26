package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	WorkspaceColl            = "jWorkspaces"
	WorkspaceConstructorName = "JWorkspace"
)

func GetWorkspaces(accountId bson.ObjectId) ([]*models.Workspace, error) {
	query := bson.M{"originId": accountId}
	return get(query)
}

func GetWorkspacesByChannelIds(ids []string) ([]*models.Workspace, error) {
	query := bson.M{"channelId": bson.M{"$in": ids}}
	return get(query)
}

func GetWorkspacesForMachine(machine *models.Machine) ([]*models.Workspace, error) {
	query := bson.M{"machineUId": machine.Uid}
	return get(query)
}

type WorkspaceContainer struct {
	Bongo Bongo             `json:"bongo_"`
	Data  *models.Workspace `json:"data"`
	*models.Workspace
}

func GetWorkspacesContainersByChannelIds(ids []string) ([]*WorkspaceContainer, error) {
	workspaces, err := GetWorkspacesByChannelIds(ids)
	if err != nil {
		return nil, err
	}

	return workspaceContain(workspaces)
}

func GetWorkspacesContainers(machine *models.Machine) ([]*WorkspaceContainer, error) {
	workspaces, err := GetWorkspacesForMachine(machine)
	if err != nil {
		return nil, err
	}

	return workspaceContain(workspaces)
}

func get(query bson.M) ([]*models.Workspace, error) {
	workspaces := []*models.Workspace{}

	queryFn := func(c *mgo.Collection) error {
		return c.Find(query).All(&workspaces)
	}

	if err := Mongo.Run(WorkspaceColl, queryFn); err != nil {
		return nil, err
	}

	return workspaces, nil
}

func workspaceContain(workspaces []*models.Workspace) ([]*WorkspaceContainer, error) {
	containers := []*WorkspaceContainer{}

	for _, workspace := range workspaces {
		bongo := Bongo{
			ConstructorName: WorkspaceConstructorName,
			InstanceId:      workspace.ObjectId.Hex(),
		}
		container := &WorkspaceContainer{bongo, workspace, workspace}

		containers = append(containers, container)
	}

	return containers, nil
}
