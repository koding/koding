package modelhelper

import (
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var (
	WorkspaceColl            = "jWorkspaces"
	WorkspaceConstructorName = "JWorkspace"
)

// RemoveWorkspace removes given WS
func RemoveWorkspace(id bson.ObjectId) error {
	return RemoveDocument(WorkspaceColl, id)
}

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

// GetWorkspaceByChannelId returns the workspace by channel's id
func GetWorkspaceByChannelId(channelID string) (*models.Workspace, error) {
	workspace := &models.Workspace{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"channelId": channelID}).One(&workspace)
	}

	err := Mongo.Run(WorkspaceColl, query)
	if err != nil {
		return nil, err
	}

	return workspace, nil
}

// CreateWorkspace creates the workspace in mongo
func CreateWorkspace(w *models.Workspace) error {
	query := insertQuery(w)
	return Mongo.Run(WorkspaceColl, query)
}

func UnsetSocialChannelFromWorkspace(machineId bson.ObjectId) error {
	query := func(c *mgo.Collection) error {
		return c.Update(
			bson.M{"_id": machineId},
			bson.M{"$unset": bson.M{"channelId": ""}},
		)
	}

	return Mongo.Run(WorkspaceColl, query)
}
