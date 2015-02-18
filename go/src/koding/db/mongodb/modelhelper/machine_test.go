package modelhelper

import (
	"koding/db/models"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"
)

func createMachine(t *testing.T) *models.Machine {
	m := &models.Machine{
		ObjectId:    bson.NewObjectId(),
		Uid:         bson.NewObjectId().Hex(),
		QueryString: "",
		IpAddress:   "",
		Domain:      "",
		Provider:    "koding",
		Label:       "",
		Slug:        "",
		Users: []models.MachineUser{
			// real owner
			models.MachineUser{
				Id:    bson.NewObjectId(),
				Sudo:  true,
				Owner: true,
			},
			// secondary owner
			models.MachineUser{
				Id:    bson.NewObjectId(),
				Sudo:  false,
				Owner: true,
			},
			// has sudo but not owner
			models.MachineUser{
				Id:    bson.NewObjectId(),
				Sudo:  true,
				Owner: false,
			},
			// random user
			models.MachineUser{
				Id:    bson.NewObjectId(),
				Sudo:  false,
				Owner: false,
			},
		},
		CreatedAt: time.Now().UTC(),
		Status: models.MachineStatus{
			State:      "running",
			ModifiedAt: time.Now().UTC(),
		},
		Assignee:    models.MachineAssignee{},
		UserDeleted: false,
	}

	err := CreateMachine(m)
	if err != nil {
		t.Fatal(err.Error())
	}

	return m
}

func TestUnshareMachine(t *testing.T) {
	initMongoConn()
	defer Close()

	m := createMachine(t)
	defer DeleteMachine(m.ObjectId)

	if err := UnshareMachineByUid(m.Uid); err != nil {
		t.Error(err)
	}

	m2, err := GetMachineByUid(m.Uid)
	if err != nil {
		t.Error(err.Error())
	}

	if len(m2.Users) != 1 {
		t.Fatalf("user count should be 1, got: %d", len(m2.Users))
	}

	if !(m2.Users[0].Sudo && m2.Users[0].Owner) {
		t.Fatalf("only owner should have sudo and owner priv.")
	}
}
