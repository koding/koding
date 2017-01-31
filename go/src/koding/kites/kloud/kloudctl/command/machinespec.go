package command

import (
	"bytes"
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
	"koding/kites/kloud/machinestate"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// Instance represents a user VM.
type Instance struct {
	SoftlayerID int
	Domain      string
	Username    string
	MachineID   string
}

// ID returns the instance's ID.
func (i *Instance) ID() string {
	return i.MachineID
}

// Label returns instance's label.
func (i *Instance) Label() string {
	return i.Domain
}

// MachineSpec describes data needed to create a machine, thus a "spec".
type MachineSpec struct {
	Environment string         `json:"environment,omitempty"`
	User        models.User    `json:"user,omitempty"`
	Group       models.Group   `json:"user,omitempty"`
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
	if spec.Group.Id.Valid() {
		return true
	}
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

// ID returns an ID of the machine.
func (spec *MachineSpec) ID() string {
	return spec.Machine.ObjectId.Hex()
}

// Label returns a label of the machine.
func (spec *MachineSpec) Label() string {
	return spec.Machine.Label
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
	dec := json.NewDecoder(bytes.NewReader(p))
	dec.UseNumber()
	if err := dec.Decode(&spec); err != nil {
		return nil, err
	}

	return &spec, nil
}

// BuildMachine ensures the user and group of the spec are
// inserted into db.
func (spec *MachineSpec) BuildMachine(createUser bool) error {
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
		group, err := modelhelper.GetGroup("koding")
		if err != nil {
			return err
		}
		spec.Machine.Groups = []models.MachineGroup{{Id: group.Id}}
	}

	// If no existing user is provided, create one.
	if !spec.HasUser() {
		// Try to lookup user by username first.
		user, err := modelhelper.GetUser(spec.Username())
		if err != nil {
			if !createUser {
				return fmt.Errorf("user %q does not exist", spec.Username())
			}

			spec.User.ObjectId = bson.NewObjectId()
			if spec.User.RegisteredAt.IsZero() {
				spec.User.RegisteredAt = time.Now()
			}

			if spec.User.LastLoginDate.IsZero() {
				spec.User.LastLoginDate = spec.User.RegisteredAt
			}

			if err = modelhelper.CreateUser(&spec.User); err != nil {
				return err
			}

			user = &spec.User
		}

		spec.User.ObjectId = user.ObjectId
		spec.User.Name = spec.Username()
	}

	// Ensure the user is assigned to the machine.
	if len(spec.Machine.Users) == 0 {
		spec.Machine.Users = []models.MachineUser{{
			Sudo:  true,
			Owner: true,
		}}
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

	m, err := modelhelper.GetMachineBySlug(spec.Machine.Users[0].Id, spec.Machine.Slug)
	if err == mgo.ErrNotFound {
		return nil
	}
	if err != nil {
		return err
	}

	switch m.State() {
	case machinestate.Building, machinestate.Starting:
		return ErrAlreadyBuilding
	case machinestate.Running:
		return ErrAlreadyRunning
	case machinestate.NotInitialized:
		spec.Machine.ObjectId = m.ObjectId
		return ErrRebuild
	default:
		return fmt.Errorf("machine state is %q; needs to be deleted and build "+
			"again (jMachine.ObjectId = %q)", m.State(), m.ObjectId.Hex())
	}
}

var (
	ErrAlreadyRunning  = errors.New("the machine is already running")
	ErrAlreadyBuilding = errors.New("the machine is already running")
	ErrRebuild         = errors.New("previous build of that machine failed, need to be rebuild")
)

// InsertMachine inserts the machine to DB and requests kloud to build it.
func (spec *MachineSpec) InsertMachine() error {
	if spec.Machine.ObjectId.Valid() {
		DefaultUi.Info(fmt.Sprintf("machine %q is going to be rebuilt", spec.Machine.ObjectId.Hex()))
		return nil
	}

	user := spec.Machine.Users[0]

	spec.Machine.ObjectId = bson.NewObjectId()
	spec.Machine.CreatedAt = time.Now()
	spec.Machine.Status.ModifiedAt = time.Now()
	spec.Machine.Assignee.AssignedAt = time.Now()
	spec.Machine.Credential = user.Username
	spec.Machine.Uid = spec.finalizeUID()
	spec.Machine.Domain = spec.Domain()
	spec.Machine.Groups = nil

	err := modelhelper.CreateMachine(&spec.Machine)
	if err != nil {
		return err
	}

	return nil
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
	"sandbox":    "sandbox.koding.io",
	"production": "koding.io",
}

func shortUID() string {
	p := make([]byte, 4)
	_, err := rand.Read(p)
	if err != nil {
		panic("internal error running PRNG: " + err.Error())
	}
	return hex.EncodeToString(p)
}
