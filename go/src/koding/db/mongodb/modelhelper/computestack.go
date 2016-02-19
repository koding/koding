package modelhelper

import (
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/stackstate"
	"time"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const ComputeStackColl = "jComputeStacks"

func GetComputeStack(id string) (*models.ComputeStack, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Not valid ObjectIdHex: '%s'", id)
	}

	computeStack := new(models.ComputeStack)
	query := func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&computeStack)
	}

	if err := Mongo.Run(ComputeStackColl, query); err != nil {
		return nil, err
	}

	return computeStack, nil
}

func GetComputeStackByGroup(slug string, accountID bson.ObjectId) (*models.ComputeStack, error) {
	var stack models.ComputeStack

	query := func(c *mgo.Collection) error {
		f := bson.M{
			"group":    slug,
			"originId": accountID,
		}
		return c.Find(f).One(&stack)
	}

	err := Mongo.Run(ComputeStackColl, query)
	if err != nil {
		return nil, err
	}

	return &stack, nil
}

func GetComputeStackByUserGroup(userID, groupID bson.ObjectId) (*models.ComputeStack, error) {
	user, err := GetUserById(userID.Hex())
	if err != nil {
		return nil, err
	}

	group, err := GetGroupById(groupID.Hex())
	if err != nil {
		return nil, err
	}

	account, err := GetAccount(user.Name)
	if err != nil {
		return nil, err
	}

	return GetComputeStackByGroup(group.Slug, account.Id)
}

func DeleteComputeStack(id string) error {
	query := func(c *mgo.Collection) error {
		return c.RemoveId(bson.ObjectIdHex(id))
	}

	return Mongo.Run(ComputeStackColl, query)
}

func SetStackState(id, reason string, state stackstate.State) error {
	if !bson.IsObjectIdHex(id) {
		return fmt.Errorf("Not valid ObjectIdHex: %q", id)
	}

	query := func(c *mgo.Collection) error {
		return c.Update(
			bson.M{
				"_id": bson.ObjectIdHex(id),
			},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
					"status.reason":     reason,
				},
			})
	}

	return Mongo.Run(ComputeStackColl, query)
}

func CreateComputeStack(stack *models.ComputeStack) error {
	query := insertQuery(stack)
	return Mongo.Run(ComputeStackColl, query)
}

func exists(selector bson.M) func(*mgo.Collection) error {
	return func(c *mgo.Collection) error {
		n, err := c.Find(selector).Count()
		if err != nil {
			return err
		}
		if n == 0 {
			return mgo.ErrNotFound
		}
		return nil
	}
}

func AddToStack(userID, groupID, machineID bson.ObjectId) error {
	stack, err := GetComputeStackByUserGroup(userID, groupID)
	if err != nil {
		return err
	}

	machine, err := GetMachine(machineID.Hex())
	if err != nil {
		return err
	}

	var found bool
	for _, g := range machine.Groups {
		if g.Id == groupID {
			found = true
			break
		}
	}

	// Add group to machine.
	if !found {
		update := func(c *mgo.Collection) error {
			g := &models.MachineGroup{Id: groupID}
			return c.Update(bson.M{"_id": machine.ObjectId}, bson.M{"$push": bson.M{"groups": g}})
		}

		err := Mongo.Run(MachinesColl, update)
		if err != nil {
			return err
		}
	}

	// Add machine to compute stack.
	m := bson.M{"machines": machine.ObjectId}
	err = Mongo.Run(ComputeStackColl, exists(m))

	if err == mgo.ErrNotFound {
		update := func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": stack.Id}, bson.M{"$push": m})
		}

		err = Mongo.Run(ComputeStackColl, update)
	}

	return err
}

func tryPull(coll string, sel, mod bson.M) error {
	update := func(c *mgo.Collection) error {
		return c.Update(sel, bson.M{"$pull": mod})
	}

	err := Mongo.Run(coll, update)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	return nil
}

func RemoveFromStack(userID, groupID, machineID bson.ObjectId) error {
	stack, err := GetComputeStackByUserGroup(userID, groupID)
	if err != nil {
		return err
	}

	machine, err := GetMachine(machineID.Hex())
	if err != nil {
		return err
	}

	// Remove group from jMachine.
	err = tryPull(MachinesColl, bson.M{"_id": machine.ObjectId}, bson.M{"groups": bson.M{"id": groupID}})
	if err != nil {
		return err
	}

	// Remove machine from stack.
	return tryPull(ComputeStackColl, bson.M{"_id": stack.Id}, bson.M{"machines": machine.ObjectId})
}
