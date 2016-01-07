package modelhelper

import (
	"koding/db/models"
	"testing"
	"time"

	"gopkg.in/mgo.v2/bson"
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
		t.Errorf(err.Error())
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
		t.Errorf("user count should be 1, got: %d", len(m2.Users))
	}

	if !(m2.Users[0].Sudo && m2.Users[0].Owner) {
		t.Errorf("only owner should have sudo and owner priv.")
	}
}

func TestGetMachinesByUsernameAndProvider(t *testing.T) {
	initMongoConn()
	defer Close()

	user := &models.User{Name: "testuser", ObjectId: bson.NewObjectId()}
	defer RemoveUser(user.Name)

	if err := CreateUser(user); err != nil {
		t.Error(err)
	}

	// koding provider machine
	m1 := &models.Machine{
		ObjectId: bson.NewObjectId(),
		Uid:      bson.NewObjectId().Hex(),
		Provider: "koding",
		Users: []models.MachineUser{
			models.MachineUser{Id: user.ObjectId, Owner: true},
		},
	}

	if err := CreateMachine(m1); err != nil {
		t.Errorf(err.Error())
	}

	defer DeleteMachine(m1.ObjectId)

	// non koding provider machine
	m2 := &models.Machine{
		ObjectId: bson.NewObjectId(),
		Uid:      bson.NewObjectId().Hex(),
		Provider: "amazon",
		Users: []models.MachineUser{
			models.MachineUser{Id: user.ObjectId, Owner: true},
		},
	}

	if err := CreateMachine(m2); err != nil {
		t.Errorf(err.Error())
	}

	defer DeleteMachine(m2.ObjectId)

	// should only get koding provider machine
	machines, err := GetMachinesByUsernameAndProvider(user.Name, m1.Provider)
	if err != nil {
		t.Error(err.Error())
	}

	if len(machines) != 1 {
		t.Errorf("machine count should be 2, got: %d", len(machines))
	}
}
