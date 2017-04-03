package modelhelper_test

import (
	"fmt"
	"testing"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	"gopkg.in/mgo.v2/bson"
)

type cleaner []func()

func (c *cleaner) add(v interface{}) {
	var fn func()
	switch model := v.(type) {
	case *models.User:
		fn = func() {
			modelhelper.RemoveUser(model.Name)
		}
	case *models.Account:
		fn = func() {
			modelhelper.RemoveAccount(model.Id)
		}
	case *models.Group:
		fn = func() {
			modelhelper.RemoveGroup(model.Id)
		}
	case *models.Machine:
		fn = func() {
			modelhelper.DeleteMachine(model.ObjectId)
		}
	case *models.ComputeStack:
		fn = func() {
			modelhelper.DeleteComputeStack(model.Id.Hex())
		}
	default:
		panic(fmt.Errorf("cleaner for %T not implemented", v))
	}
	*c = append(*c, fn)
}

func (c cleaner) clean() {
	for _, fn := range c {
		fn()
	}
}

func testFixture(t *testing.T) (*models.User, *models.Group, *models.Machine, *models.Account, func()) {
	var c cleaner

	user, account, err := modeltesthelper.CreateUser(bson.NewObjectId().Hex())
	if err != nil {
		c.clean()
		t.Fatalf("error creating user: %s", err)
	}

	c.add(user)
	c.add(account)

	group, err := createGroup()
	if err != nil {
		c.clean()
		t.Fatalf("error creating group: %s", err)
	}

	c.add(group)

	machine := &models.Machine{
		ObjectId: bson.NewObjectId(),
		Uid:      bson.NewObjectId().Hex(),
		Provider: "koding",
		Users: []models.MachineUser{
			{
				Id:    user.ObjectId,
				Owner: true,
			},
		},
	}

	if err := modelhelper.CreateMachine(machine); err != nil {
		c.clean()
		t.Fatalf("error creating machine: %s", err)
	}

	c.add(machine)

	return user, group, machine, account, c.clean
}

func TestAddAndRemoveFromStack(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	user, group, machine, account, clean := testFixture(t)
	defer clean()

	sd := &modelhelper.StackDetails{
		UserID:    user.ObjectId,
		GroupID:   group.Id,
		MachineID: machine.ObjectId,

		UserName:  user.Name,
		GroupSlug: group.Slug,

		AccountID: account.Id,
		BaseID:    bson.ObjectIdHex("53fe557af052f8e9435a04fa"),
	}

	// Add for a first time.

	err := modelhelper.AddToStack(sd)
	if err != nil {
		t.Fatalf("error adding machine %q to stack: %s", machine.ObjectId.Hex(), err)
	}

	s, err := modelhelper.GetComputeStackByGroup(group.Slug, account.Id)
	if err != nil {
		t.Fatalf("error getting stack for koding, %q: %s", account.Id.Hex(), err)
	}

	if len(s.Machines) != 1 {
		t.Fatalf("want 1 machine, got %d", len(s.Machines))
	}

	if s.Machines[0] != machine.ObjectId {
		t.Fatalf("want machine %q to be added to stack, got %q instead", machine.ObjectId.Hex(), s.Machines[0].Hex())
	}

	m, err := modelhelper.GetMachine(machine.ObjectId.Hex())
	if err != nil {
		t.Fatalf("error getting machine %q: %s", machine.ObjectId.Hex(), err)
	}

	if len(m.Groups) != 1 {
		t.Fatalf("want 1 group, got %d", len(m.Groups))
	}

	if m.Groups[0].Id != group.Id {
		t.Fatalf("want group %q, got %q", group.Id.Hex(), m.Groups[0].Id.Hex())
	}

	// Adding for a second time must be idempotent.

	err = modelhelper.AddToStack(sd)
	if err != nil {
		t.Fatalf("error adding machine %q to stack: %s", machine.ObjectId.Hex(), err)
	}

	s2, err := modelhelper.GetComputeStackByGroup(group.Slug, account.Id)
	if err != nil {
		t.Fatalf("error getting stack for koding, %q: %s", account.Id.Hex(), err)
	}

	if s.Id != s2.Id {
		t.Errorf("want jComputeStack.ObjetId %q; got %q", s.Id.Hex(), s2.Id.Hex())
	}

	if len(s.Machines) != 1 {
		t.Fatalf("want 1 machine, got %d", len(s.Machines))
	}

	if s.Machines[0] != machine.ObjectId {
		t.Fatalf("want machine %q to be added to stack, got %q instead", machine.ObjectId.Hex(), s.Machines[0].Hex())
	}

	m, err = modelhelper.GetMachine(machine.ObjectId.Hex())
	if err != nil {
		t.Fatalf("error getting machine %q: %s", machine.ObjectId.Hex(), err)
	}

	if len(m.Groups) != 1 {
		t.Fatalf("want 1 group, got %d", len(m.Groups))
	}

	if m.Groups[0].Id != group.Id {
		t.Fatalf("want group %q, got %q", group.Id.Hex(), m.Groups[0].Id.Hex())
	}

	// Remove from stack.
	err = modelhelper.RemoveFromStack(sd)
	if err != nil {
		t.Fatalf("error removing %q from stack: %s", machine.ObjectId.Hex(), err)
	}

	s3, err := modelhelper.GetComputeStackByGroup(group.Slug, account.Id)
	if err != nil {
		t.Fatalf("error getting stack for koding, %q: %s", account.Id.Hex(), err)
	}

	if len(s3.Machines) != 0 {
		t.Fatalf("want 0 machine, got %d", len(s.Machines))
	}

	m, err = modelhelper.GetMachine(machine.ObjectId.Hex())
	if err != nil {
		t.Fatalf("error getting machine %q: %s", machine.ObjectId.Hex(), err)
	}

	if len(m.Groups) != 0 {
		t.Fatalf("want 0 group, got %d", len(m.Groups))
	}
}
