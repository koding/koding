package command

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// MachineSpec describes data needed to create a machine, thus a "spec".
type MachineSpec struct {
	Environment string         `json:"environment,omitempty"`
	User        models.User    `json:"user,omitempty"`
	Machine     models.Machine `json:"machine,omitempty"`
}

// HasMachine returns true when spec describes aleady existing machine.
func (spec *MachineSpec) HasMachine() bool {
	return spec.Machine.ObjectId.Valid()
}

// HasUser returns true when spec describes already existing user.
func (spec *MachineSpec) HasUser() bool {
	if spec.User.ObjectId.Valid() {
		return true
	}
	return len(spec.Machine.Users) != 0 && spec.Machine.Users[0].Id.Valid()
}

// HasGroup returns true when spec describes already existing group.
func (spec *MachineSpec) HasGroup() bool {
	return len(spec.Machine.Groups) != 0 && spec.Machine.Groups[0].Id.Valid()
}

// Username returns the name of the user the requests machine creation.
func (spec *MachineSpec) Username() string {
	if spec.User.Name != "" {
		return spec.User.Name
	}
	if len(spec.Machine.Users) == 0 {
		return ""
	}
	return spec.Machine.Users[0].Username
}

// Domain returns the domain of the machine.
func (spec *MachineSpec) Domain() string {
	return fmt.Sprintf("%s.%s.%s", spec.Machine.Uid, spec.Machine.Credential, dnsZones[spec.env()])
}

func (spec *MachineSpec) finalizeUID() string {
	return spec.Machine.Uid[:4] + shortUID()
}

func (spec *MachineSpec) env() string {
	if spec.Environment != "" {
		return spec.Environment
	}
	return "dev"
}

// ParseMachineSpec parses the given spec file and templates the variables
// with the given vars.
func ParseMachineSpec(file string) (*MachineSpec, error) {
	var p []byte
	var err error
	if file == "-" {
		p, err = ioutil.ReadAll(os.Stdin)
	} else {
		p, err = ioutil.ReadFile(file)
	}
	if err != nil {
		return nil, err
	}

	var spec MachineSpec
	if err := json.Unmarshal(p, &spec); err != nil {
		return nil, err
	}

	return &spec, nil
}

// BuildUserAndGroup ensures the user and group of the spec are
// inserted into db.
func (spec *MachineSpec) BuildUserAndGroup() error {
	// If MachineID is not nil, ensure it exists and reuse it if it does.
	if spec.HasMachine() {
		m, err := modelhelper.GetMachine(spec.Machine.ObjectId.Hex())
		if err != nil {
			return err
		}
		spec.Machine = *m
		return nil
	}
	// If no existing group is provided, create or use 'hackathon' one,
	// which will make VMs invisible to users until they're assigned
	// to proper group before the hackathon.
	if !spec.HasGroup() {
		if spec.Environment != "dev" {
			return errors.New("no group specified")
		}
		group, err := getOrCreateHackathonGroup()
		if err != nil {
			return err
		}
		if len(spec.Machine.Groups) == 0 {
			spec.Machine.Groups = make([]models.MachineGroup, 1)
		}
		spec.Machine.Groups[0].Id = group.Id
	}
	// If no existing user is provided, create one.
	if !spec.HasUser() {
		query := func(c *mgo.Collection) error {
			// Try to lookup user by username first.
			var user models.User
			err := c.Find(bson.M{"username": spec.Username()}).One(&user)
			if err == nil {
				spec.User.ObjectId = user.ObjectId
				spec.User.Name = spec.Username()
				return nil
			}
			// If the lookup fails, create new one.
			spec.User.ObjectId = bson.NewObjectId()
			if spec.User.RegisteredAt.IsZero() {
				spec.User.RegisteredAt = time.Now()
			}
			if spec.User.LastLoginDate.IsZero() {
				spec.User.LastLoginDate = spec.User.RegisteredAt
			}
			return c.Insert(&spec.User)
		}
		err := modelhelper.Mongo.Run("jUsers", query)
		if err != nil {
			return err
		}
		// For newly created user increment the member count.
		query = func(c *mgo.Collection) error {
			var group models.Group
			id := spec.Machine.Groups[0].Id
			err := c.FindId(id).One(&group)
			if err != nil {
				return err
			}
			var count int
			members, ok := group.Counts["members"]
			if ok {
				count, ok = members.(int)
				if !ok {
					// If the member count is unavaible to skip updating
					// and return.
					return nil
				}
			}
			group.Counts["members"] = count + 1
			return c.UpdateId(id, &group)
		}
		err = modelhelper.Mongo.Run("jGroups", query)
		if err != nil {
			return err
		}
	}
	// Ensure the user is assigned to the machine.
	if len(spec.Machine.Users) == 0 {
		spec.Machine.Users = make([]models.MachineUser, 1)
	}
	if spec.Machine.Users[0].Id == "" {
		spec.Machine.Users[0].Id = spec.User.ObjectId
	}
	if spec.Machine.Users[0].Username == "" {
		spec.Machine.Users[0].Username = spec.User.Name
	}
	// Lookup username for existing user.
	if spec.Machine.Users[0].Username == "" {
		user, err := modelhelper.GetUserById(spec.Machine.Users[0].Id.Hex())
		if err != nil {
			return err
		}
		spec.Machine.Users[0].Username = user.Name
	}
	// Lookup group and init Uid.
	group, err := modelhelper.GetGroupById(spec.Machine.Groups[0].Id.Hex())
	if err != nil {
		return err
	}
	spec.Machine.Uid = fmt.Sprintf("u%c%c%c",
		spec.Machine.Users[0].Username[0],
		group.Slug[0],
		spec.Machine.Provider[0],
	)
	return nil
}

// BuildMachine inserts the machine to DB and requests kloud to build it.
func (spec *MachineSpec) BuildMachine() error {
	// Insert the machine to the db.
	query := func(c *mgo.Collection) error {
		spec.Machine.ObjectId = bson.NewObjectId()
		spec.Machine.CreatedAt = time.Now()
		spec.Machine.Status.ModifiedAt = time.Now()
		spec.Machine.Credential = spec.Machine.Users[0].Username
		spec.Machine.Uid = spec.finalizeUID()
		spec.Machine.Domain = spec.Domain()
		return c.Insert(&spec.Machine)
	}
	return modelhelper.Mongo.Run("jMachines", query)
}

// Copy gives a copy of the spec value.
func (spec *MachineSpec) Copy() *MachineSpec {
	var specCopy MachineSpec
	p, err := json.Marshal(spec)
	if err != nil {
		panic("internal error copying a MachineSpec: " + err.Error())
	}
	err = json.Unmarshal(p, &specCopy)
	if err != nil {
		panic("internal error copying a MachineSpec: " + err.Error())
	}
	return &specCopy
}

var dnsZones = map[string]string{
	"dev":        "dev.koding.io",
	"sandbox":    "sandbox.koding.com",
	"production": "koding.com",
}

func getOrCreateHackathonGroup() (*models.Group, error) {
	var group models.Group
	query := func(c *mgo.Collection) error {
		err := c.Find(bson.M{"slug": "hackathon"}).One(&group)
		if err == mgo.ErrNotFound {
			group = models.Group{
				Id:         bson.NewObjectId(),
				Body:       "Preallocated VM pool for Hackathon",
				Title:      "Hackathon",
				Slug:       "hackathon",
				Privacy:    "private",
				Visibility: "invisible",
				Counts: map[string]interface{}{
					"members": 0,
				},
			}
			err = c.Insert(&group)
		}
		return err
	}
	if err := modelhelper.Mongo.Run("jGroups", query); err != nil {
		return nil, err
	}
	return &group, nil
}

func shortUID() string {
	p := make([]byte, 4)
	_, err := rand.Read(p)
	if err != nil {
		panic("internal error running PRNG: " + err.Error())
	}
	return hex.EncodeToString(p)
}
