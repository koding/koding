package modelhelper_test

import (
	"net/url"
	"testing"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"koding/tools/utils"

	"github.com/koding/kite/protocol"
	uuid "github.com/satori/go.uuid"
	"gopkg.in/mgo.v2/bson"
)

func createMachine(t *testing.T) *models.Machine {
	m := &models.Machine{
		ObjectId:    bson.NewObjectId(),
		Uid:         bson.NewObjectId().Hex(),
		QueryString: (&protocol.Kite{ID: uuid.NewV4().String()}).String(),
		IpAddress:   utils.RandomString(),
		RegisterURL: (&url.URL{
			Scheme: "http",
			Host:   utils.RandomString() + ":56789",
			Path:   "/kite",
		}).String(),
		Provider: "koding",
		Users: []models.MachineUser{
			// real owner
			{
				Id:       bson.NewObjectId(),
				Sudo:     true,
				Owner:    true,
				Username: "rafal",
			},
			// secondary owner
			{
				Id:    bson.NewObjectId(),
				Sudo:  false,
				Owner: true,
			},
			// has sudo but not owner
			{
				Id:    bson.NewObjectId(),
				Sudo:  true,
				Owner: false,
			},
			// random user
			{
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

	err := modelhelper.CreateMachine(m)
	if err != nil {
		t.Errorf("createMachine()=%s", err)
	}

	return m
}

func createMachines(n int, t *testing.T) ([]*models.Machine, error) {
	machines := make([]*models.Machine, n)

	for i := range machines {
		machines[i] = createMachine(t)
	}

	return machines, nil
}

func TestUnshareMachine(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	m := createMachine(t)
	defer modelhelper.DeleteMachine(m.ObjectId)

	if err := modelhelper.UnshareMachineByUid(m.Uid); err != nil {
		t.Error(err)
	}

	m2, err := modelhelper.GetMachineByUid(m.Uid)
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
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	user, _, err := modeltesthelper.CreateUser(bson.NewObjectId().Hex())
	if err != nil {
		t.Error(err)
	}
	defer modelhelper.RemoveUser(user.Name)

	// koding provider machine
	m1 := &models.Machine{
		ObjectId: bson.NewObjectId(),
		Uid:      bson.NewObjectId().Hex(),
		Provider: "koding",
		Users: []models.MachineUser{
			{Id: user.ObjectId, Owner: true},
		},
	}

	if err := modelhelper.CreateMachine(m1); err != nil {
		t.Errorf(err.Error())
	}

	defer modelhelper.DeleteMachine(m1.ObjectId)

	// non koding provider machine
	m2 := &models.Machine{
		ObjectId: bson.NewObjectId(),
		Uid:      bson.NewObjectId().Hex(),
		Provider: "amazon",
		Users: []models.MachineUser{
			{Id: user.ObjectId, Owner: true},
		},
	}

	if err := modelhelper.CreateMachine(m2); err != nil {
		t.Errorf(err.Error())
	}

	defer modelhelper.DeleteMachine(m2.ObjectId)

	// should only get koding provider machine
	machines, err := modelhelper.GetMachinesByUsernameAndProvider(user.Name, m1.Provider)
	if err != nil {
		t.Error(err.Error())
	}

	if len(machines) != 1 {
		t.Errorf("machine count should be 2, got: %d", len(machines))
	}
}
