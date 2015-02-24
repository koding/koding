package modelhelper

import (
	"koding/db/models"
	"math/rand"
	"strconv"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"
)

func createWorkspace() (*models.Workspace, error) {
	ws := &models.Workspace{
		ObjectId:     bson.NewObjectId(),
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
		t.Fatalf(err.Error())
	}

	if w2 == nil {
		t.Fatalf("couldnt fetch workspace by channel id got nil, expected: %+v", w)
	}

	if w2.ObjectId.Hex() != w.ObjectId.Hex() {
		t.Fatalf("workspaces are not same: expected: %+v, got: ", w)
	}

	_, err = GetWorkspaceByChannelId(strconv.FormatInt(rand.Int63(), 10))
	if err == nil {
		t.Fatalf("we should not be able to find the WS")
	}
}
