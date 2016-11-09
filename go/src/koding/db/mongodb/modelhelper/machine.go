package modelhelper

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/machinestate"
	"time"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

type Bongo struct {
	ConstructorName string `json:"constructorName"`
	InstanceId      string `json:"instanceId"`
}

type MachineContainer struct {
	Bongo Bongo           `json:"bongo_"`
	Data  *models.Machine `json:"data"`
	*models.Machine
}

var (
	MachinesColl           = "jMachines"
	MachineConstructorName = "JMachine"
)

func GetMachine(id string) (*models.Machine, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Invalid machine id: %q", id)
	}

	machine := &models.Machine{}
	err := Mongo.Run(MachinesColl, func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&machine)
	})
	if err != nil {
		return nil, err
	}

	return machine, nil
}

// NOTE(rjeczalik): This method is used only by kloudctl dev tool, which is run once per year and
// when performance does not matter. If you'd want to use in production, please take care about
// indices or improving the query.
func GetMachineBySlug(userID bson.ObjectId, slug string) (*models.Machine, error) {
	query := bson.M{
		"slug": slug,
		"users": bson.M{
			"$elemMatch": bson.M{"id": userID, "owner": true},
		},
	}

	m, err := findMachine(query)
	if err != nil {
		return nil, err
	}
	if len(m) == 0 {
		return nil, mgo.ErrNotFound
	}
	if len(m) != 1 {
		return nil, fmt.Errorf("GetMachinyBySlug: want 1 result, got %d", len(m))
	}

	return m[0], nil
}

// NOTE(rjeczalik): see comment for GetMachineBySlug
func GetMachinesByProvider(userID bson.ObjectId, provider string) ([]*models.Machine, error) {
	query := bson.M{
		"provider": provider,
		"users": bson.M{
			"$elemMatch": bson.M{"id": userID, "owner": true},
		},
	}

	m, err := findMachine(query)
	if err != nil {
		return nil, err
	}
	if len(m) == 0 {
		return nil, mgo.ErrNotFound
	}

	return m, nil
}

func GetMachines(userId bson.ObjectId) ([]*MachineContainer, error) {
	machines := []*models.Machine{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"users.id": userId}).All(&machines)
	}

	err := Mongo.Run(MachinesColl, query)
	if err != nil {
		return nil, err
	}

	containers := []*MachineContainer{}

	for _, machine := range machines {
		bongo := Bongo{
			ConstructorName: MachineConstructorName,
			InstanceId:      machine.ObjectId.Hex(),
		}
		container := &MachineContainer{bongo, machine, machine}

		containers = append(containers, container)
	}

	return containers, nil
}

var (
	MachineStateRunning   = "Running"
	MachineProviderKoding = "koding"
)

func GetRunningVms(provider string) ([]*models.Machine, error) {
	query := bson.M{"status.state": MachineStateRunning, "provider": provider}
	return findMachine(query)
}

func GetMachinesByUsernameAndProvider(username, provider string) ([]*models.Machine, error) {
	user, err := GetUser(username)
	if err != nil {
		return nil, err
	}

	query := bson.M{
		"provider": provider,
		"users": bson.M{
			"$elemMatch": bson.M{"id": user.ObjectId, "owner": true},
		},
	}

	return findMachine(query)
}

func GetMachinesByUsername(username string) ([]*models.Machine, error) {
	user, err := GetUser(username)
	if err != nil {
		return nil, err
	}

	query := bson.M{"users": bson.M{
		"$elemMatch": bson.M{"id": user.ObjectId, "owner": true},
	}}

	return findMachine(query)
}

func GetParticipatedMachinesByUsername(username string) ([]*models.Machine, error) {
	user, err := GetUser(username)
	if err != nil {
		return nil, err
	}

	query := bson.M{"users": bson.M{
		"$elemMatch": bson.M{"id": user.ObjectId},
	}}

	return findMachine(query)
}

// GetMachineFieldsByUsername retrieves a slice of machines owned by the given user,
// limited to the specified fields.
func GetMachineFieldsByUsername(username string, fields []string) ([]*models.Machine, error) {
	user, err := GetUser(username)
	if err != nil {
		return nil, err
	}

	query := bson.M{"users": bson.M{
		"$elemMatch": bson.M{"id": user.ObjectId, "owner": true},
	}}

	return findMachineFields(query, fields)
}

func GetOwnMachines(userId bson.ObjectId) ([]*MachineContainer, error) {
	query := bson.M{
		"users": bson.M{
			"$elemMatch": bson.M{
				"id":    userId,
				"owner": true,
			},
		},
	}

	return findMachineContainers(query)
}

func GetGroupMachines(userId bson.ObjectId, group *models.Group) ([]*MachineContainer, error) {
	query := bson.M{
		"users": bson.M{
			"$elemMatch": bson.M{
				"id": userId,
			},
		},
		"groups": bson.M{
			"$elemMatch": bson.M{
				"id": group.Id,
			},
		},
	}

	return findMachineContainers(query)
}

func GetOwnGroupMachines(userId bson.ObjectId, group *models.Group) ([]*MachineContainer, error) {
	query := bson.M{
		"users": bson.M{
			"$elemMatch": bson.M{
				"id":    userId,
				"owner": true,
			},
		},
		"groups": bson.M{
			"$elemMatch": bson.M{
				"id": group.Id,
			},
		},
	}

	return findMachineContainers(query)
}

func GetSharedMachines(userId bson.ObjectId) ([]*MachineContainer, error) {
	query := bson.M{
		"users": bson.M{
			"$elemMatch": bson.M{
				"id":        userId,
				"owner":     false,
				"permanent": true,
			},
		},
	}

	return findMachineContainers(query)
}

func GetSharedGroupMachines(userId bson.ObjectId, group *models.Group) ([]*MachineContainer, error) {
	query := bson.M{
		"users": bson.M{
			"$elemMatch": bson.M{
				"id":        userId,
				"owner":     false,
				"permanent": true,
			},
		},
		"groups": bson.M{
			"$elemMatch": bson.M{
				"id": group.Id,
			},
		},
	}

	return findMachineContainers(query)
}

func GetCollabMachines(userId bson.ObjectId, group *models.Group) ([]*MachineContainer, error) {
	query := bson.M{
		"users": bson.M{
			"$elemMatch": bson.M{
				"id":        userId,
				"owner":     false,
				"permanent": bson.M{"$ne": true},
			},
		},
		"groups": bson.M{
			"$elemMatch": bson.M{
				"id": group.Id,
			},
		},
	}

	return findMachineContainers(query)
}

func findMachineContainers(query bson.M) ([]*MachineContainer, error) {
	machines, err := findMachine(query)
	if err != nil {
		return nil, err
	}

	containers := []*MachineContainer{}

	for _, machine := range machines {
		bongo := Bongo{
			ConstructorName: MachineConstructorName,
			InstanceId:      "1", // TODO: what should go here?
		}

		container := &MachineContainer{bongo, machine, machine}
		containers = append(containers, container)
	}

	return containers, nil
}

// GetMachineByUid returns the machine by its uid field
func GetMachineByUid(uid string) (*models.Machine, error) {
	machine := &models.Machine{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"uid": uid}).One(machine)
	}

	err := Mongo.Run(MachinesColl, query)
	if err != nil {
		return nil, err
	}

	return machine, nil
}

// UnshareMachineByUid unshares the machine from all other users except the
// owner
func UnshareMachineByUid(uid string) error {
	machine, err := GetMachineByUid(uid)
	if err != nil {
		return err
	}

	machineOwner := machine.Owner()
	if machineOwner == nil {
		return errors.New("owner couldnt found")
	}

	owner := []models.MachineUser{*machineOwner}

	s := Selector{"_id": machine.ObjectId}
	o := Selector{"$set": Selector{
		"users": owner,
	}}

	query := func(c *mgo.Collection) error {
		return c.Update(s, o)
	}

	return Mongo.Run(MachinesColl, query)
}

// RemoveUsersFromMachineByIds removes the given users from JMachine document
func RemoveUsersFromMachineByIds(uid string, ids []bson.ObjectId) error {
	machine, err := GetMachineByUid(uid)
	if err != nil {
		return err
	}

	users := make([]models.MachineUser, 0)

	for _, user := range machine.Users {
		toBeAdded := true
		for _, id := range ids {
			if user.Id.Hex() == id.Hex() {
				toBeAdded = false
			}
		}

		if toBeAdded {
			// we couldnt find the account in -to be removed list-, so add it
			// back
			users = append(users, user)
		}
	}

	s := Selector{"_id": machine.ObjectId}
	o := Selector{"$set": Selector{
		"users": users,
	}}

	query := func(c *mgo.Collection) error {
		return c.Update(s, o)
	}

	return Mongo.Run(MachinesColl, query)
}

func findMachine(query bson.M) ([]*models.Machine, error) {
	return findMachineFields(query, nil)
}

// findMachineFields retreives the machines matching the given query, only returning
// the given fields.
//
// If fields is empty, an empty projection will be sent to mongo. If fields is
// *nil*, no projection is sent to mongo.
func findMachineFields(query bson.M, fields []string) ([]*models.Machine, error) {
	machines := []*models.Machine{}

	queryFn := func(c *mgo.Collection) error {
		q := c.Find(query)

		if fields != nil {
			selects := bson.M{}
			for _, f := range fields {
				selects[f] = 1
			}

			q.Select(selects)
		}

		iter := q.Iter()

		for m := new(models.Machine); iter.Next(m); m = new(models.Machine) {
			machines = append(machines, m)
		}

		return iter.Close()
	}

	if err := Mongo.Run(MachinesColl, queryFn); err != nil {
		return nil, err
	}

	return machines, nil
}

func UpdateMachineAlwaysOn(machineId bson.ObjectId, alwaysOn bool) error {
	query := func(c *mgo.Collection) error {
		return c.Update(
			bson.M{"_id": machineId},
			bson.M{"$set": bson.M{"meta.alwaysOn": alwaysOn}},
		)
	}

	return Mongo.Run(MachinesColl, query)
}

func UpdateMachine(machineId bson.ObjectId, change interface{}) error {
	query := func(c *mgo.Collection) error {
		return c.UpdateId(machineId, change)
	}

	return Mongo.Run(MachinesColl, query)
}

func ChangeMachineState(machineId bson.ObjectId, reason string, state machinestate.State) error {
	query := func(c *mgo.Collection) error {
		return c.Update(
			bson.M{"_id": machineId},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
					"status.reason":     reason,
				},
			},
		)
	}

	return Mongo.Run(MachinesColl, query)
}

// CheckAndUpdate state updates only if the given machine id is not used by
// anyone else
func CheckAndUpdateState(machineId bson.ObjectId, state machinestate.State) error {
	query := func(c *mgo.Collection) error {
		return c.Update(
			bson.M{
				"_id": machineId,
				"assignee.inProgress": false, // only update if it's not locked by someone else
			},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
				},
			},
		)
	}

	return Mongo.Run(MachinesColl, query)
}

func CreateMachine(m *models.Machine) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(m)
	}

	return Mongo.Run(MachinesColl, query)
}

// DeleteMachine deletes the machine from mongodb, it is here just for cleaning
// purposes(after tests), machines should not be removed from database  unless
// you are kloud
func DeleteMachine(id bson.ObjectId) error {
	selector := bson.M{"_id": id}

	query := func(c *mgo.Collection) error {
		return c.Remove(selector)
	}

	return Mongo.Run(MachinesColl, query)
}

func CreateMachineForUser(m *models.Machine, u *models.User) error {
	m.Users = []models.MachineUser{
		{Id: u.ObjectId, Sudo: true, Owner: true},
	}

	return CreateMachine(m)
}

func RemoveAllMachinesForUser(userId bson.ObjectId) error {
	selector := bson.M{"users": bson.M{"id": userId}}

	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(selector)
		return err
	}

	return Mongo.Run(MachinesColl, query)
}

func UnsetKlientMissingAt(userId bson.ObjectId) error {
	query := func(c *mgo.Collection) error {
		return c.UpdateId(
			userId,
			bson.M{"$unset": bson.M{"assignee.klientMissingAt": ""}},
		)
	}

	return Mongo.Run(MachinesColl, query)
}

func UpdateMachines(update bson.M, ids ...bson.ObjectId) error {
	query := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(
			bson.M{
				"_id": bson.M{"$in": ids},
			},
			update,
		)

		return err
	}

	return Mongo.Run(MachinesColl, query)
}
