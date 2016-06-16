package modelhelper

import (
	"errors"
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

func NewDefaultStack(baseID, accountID bson.ObjectId, groupSlug string) *models.ComputeStack {
	// TODO(rjeczalik): use named struct
	status := (&models.ComputeStack{}).Status
	status.State = "NotInitialized"

	return &models.ComputeStack{
		Id:          bson.NewObjectId(),
		BaseStackId: baseID,
		OriginId:    accountID,
		Group:       groupSlug,
		Config: bson.M{
			"groupStack":           true,
			"KODINGINSTALLER":      "v1.0",
			"KODING_BASE_PACKAGES": "mc nodejs python sl screen",
			"DEBIAN_FRONTEND":      "noninteractive",
		},
		Meta: bson.M{
			"createdAt":  time.Now(),
			"modifiedAt": time.Now(),
			"tags":       nil,
			"views":      nil,
			"votes":      nil,
			"likes":      0,
		},
		Status: status,
		Title:  "Default Koding stack",
	}
}

type StackDetails struct {
	// Required.
	UserID    bson.ObjectId
	GroupID   bson.ObjectId
	MachineID bson.ObjectId

	UserName  string
	GroupSlug string

	// Optional; needed when we want to create missing stack.
	AccountID bson.ObjectId
	BaseID    bson.ObjectId
}

func (sd *StackDetails) Valid() error {
	if !sd.UserID.Valid() {
		return errors.New("user ID is invalid")
	}

	if !sd.GroupID.Valid() {
		return errors.New("group ID is invalid")
	}

	if !sd.MachineID.Valid() {
		return errors.New("machine ID is invalid")
	}

	if sd.UserName == "" {
		return errors.New("user name is empty")
	}

	if sd.GroupSlug == "" {
		return errors.New("group name is empty")
	}

	return nil
}

func AddToStack(sd *StackDetails) error {
	if err := sd.Valid(); err != nil {
		return err
	}

	machine, err := GetMachine(sd.MachineID.Hex())
	if err != nil {
		return fmt.Errorf("failed to get machine for ID=%q: %s", sd.MachineID.Hex(), err)
	}

	var foundGroup bool
	for _, g := range machine.Groups {
		if g.Id == sd.GroupID {
			foundGroup = true
			break
		}
	}

	var foundUser bool
	for _, u := range machine.Users {
		if u.Id == sd.UserID {
			foundUser = true
			break
		}
	}

	// Add group to machine.
	if !foundGroup {
		update := func(c *mgo.Collection) error {
			g := &models.MachineGroup{Id: sd.GroupID}
			return c.Update(bson.M{"_id": sd.MachineID}, bson.M{"$push": bson.M{"groups": g}})
		}

		err := Mongo.Run(MachinesColl, update)
		if err != nil {
			return fmt.Errorf("failed to update group of machineID=%q: %s", sd.MachineID.Hex(), err)
		}
	}

	// Add user to machine.
	if !foundUser {
		update := func(c *mgo.Collection) error {
			u := &models.MachineUser{Id: sd.UserID, Owner: true, Sudo: true, Username: sd.UserName}
			return c.Update(bson.M{"_id": sd.MachineID}, bson.M{"$push": bson.M{"users": u}})
		}

		err = Mongo.Run(MachinesColl, update)
		if err != nil {
			return fmt.Errorf("failed to update user of machineID=%q: %s", sd.MachineID.Hex(), err)
		}
	}

	// Get or create stack.
	stack, err := GetComputeStackByGroup(sd.GroupSlug, sd.AccountID)
	if err == mgo.ErrNotFound && sd.BaseID.Valid() && sd.AccountID.Valid() {
		stack = NewDefaultStack(sd.BaseID, sd.AccountID, sd.GroupSlug)

		insert := func(c *mgo.Collection) error {
			return c.Insert(stack)
		}

		err = Mongo.Run(ComputeStackColl, insert)
		if err != nil {
			return fmt.Errorf("failed to insert compute stack for baseID=%q, accountID=%q: %s", sd.BaseID.Hex(), sd.AccountID.Hex(), err)
		}
	}
	if err != nil {
		return fmt.Errorf("failed to get compute stack for userID=%q and groupID=%q: %s", sd.UserID.Hex(), sd.GroupID.Hex(), err)
	}

	// Add machine to compute stack.
	m := bson.M{"_id": stack.Id, "machines": sd.MachineID}
	err = Mongo.Run(ComputeStackColl, exists(m))

	if err == mgo.ErrNotFound {
		m = bson.M{"machines": sd.MachineID}

		update := func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": stack.Id}, bson.M{"$push": m})
		}

		err = Mongo.Run(ComputeStackColl, update)
		if err != nil {
			return fmt.Errorf("failed to update compute stack stackID=%q with machineID=%q: %s", stack.Id.Hex(), sd.MachineID.Hex(), err)
		}
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

func RemoveFromStack(sd *StackDetails) error {
	if err := sd.Valid(); err != nil {
		return err
	}

	stack, err := GetComputeStackByGroup(sd.GroupSlug, sd.AccountID)
	if err != nil {
		return fmt.Errorf("failed to get compute stack for group=%q, accountID=%q: %s", sd.GroupSlug, sd.AccountID.Hex(), err)
	}

	// Remove group from jMachine.
	err = tryPull(MachinesColl, bson.M{"_id": sd.MachineID}, bson.M{"groups": bson.M{"id": sd.GroupID}})
	if err != nil {
		return err
	}

	// Remove machine from stack.
	return tryPull(ComputeStackColl, bson.M{"_id": stack.Id}, bson.M{"machines": sd.MachineID})
}

func UpdateStack(stackID bson.ObjectId, change interface{}) error {
	return Mongo.Run(ComputeStackColl, func(c *mgo.Collection) error {
		return c.UpdateId(stackID, change)
	})
}
