package modelhelper

import (
	"koding/db/models"
	"math/rand"
	"strconv"
	"testing"
	"time"

	"gopkg.in/mgo.v2/bson"
)

func createWorkspace() (*models.Workspace, error) {
	ws := &models.Workspace{
		ObjectId:     bson.NewObjectId(),
		OriginId:     bson.NewObjectId(),
		Name:         "My Workspace",
		Slug:         "my-workspace",
		ChannelId:    strconv.FormatInt(rand.Int63(), 10),
		MachineUID:   bson.NewObjectId().Hex(),
		MachineLabel: "koding-vm-0",
		Owner:        "cihangir",
		RootPath:     "/home/cihangir",
		IsDefault:    true,
	}

	return ws, CreateWorkspace(ws)
}

func TestGetWorkspaceByChannelId(t *testing.T) {
	initMongoConn()
	defer Close()
	rand.Seed(time.Now().UnixNano())

	w, err := createWorkspace()
	if err != nil {
		t.Fatalf(err.Error())
	}

	w2, err := GetWorkspaceByChannelId(w.ChannelId)
	if err != nil {
		t.Errorf(err.Error())
	}

	if w2 == nil {
		t.Errorf("couldnt fetch workspace by channel id got nil, expected: %+v", w)
	}

	if w2.ObjectId.Hex() != w.ObjectId.Hex() {
		t.Errorf("workspaces are not same: expected: %+v, got: ", w)
	}

	_, err = GetWorkspaceByChannelId(strconv.FormatInt(rand.Int63(), 10))
	if err == nil {
		t.Errorf("we should not be able to find the WS")
	}
}

func TestUnsetSocialChannelFromWorkspace(t *testing.T) {
	initMongoConn()
	defer Close()
	rand.Seed(time.Now().UnixNano())

	w, err := createWorkspace()
	if err != nil {
		t.Fatalf(err.Error())
	}

	// first fetch it
	w2, err := GetWorkspaceByChannelId(w.ChannelId)
	if err != nil {
		t.Errorf(err.Error())
	}

	if w2 == nil {
		t.Errorf("couldnt fetch workspace by channel id got nil, expected: %+v", w)
	}

	if w2.ObjectId.Hex() != w.ObjectId.Hex() {
		t.Errorf("workspaces are not same: expected: %+v, got: ", w)
	}

	err = UnsetSocialChannelFromWorkspace(w.ObjectId)
	if err != nil {
		t.Errorf("we should be able to unset social channel id")
	}

	_, err = GetWorkspaceByChannelId(w.ChannelId)
	if err == nil {
		t.Errorf("we should not be able to find the WS")
	}
}
