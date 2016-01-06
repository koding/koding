package command

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"html/template"
	"io/ioutil"
	"os"
	"strings"
	"time"

	"koding/db/models"
	"koding/db/mongodb"

	"github.com/fatih/structs"
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

// MachineSpecVars represents variables accessible from within the spec template.
type MachineSpecVars struct {
	Env         string `json:"env,omitempty"`
	UserID      string `json:"userId,omitempty"`
	Username    string `json:"username,omitempty"`
	Email       string `json:"email,omitempty"`
	Salt        string `json:"salt,omitempty"`
	Password    string `json:"password,omitempty"`
	MachineID   string `json:"machineId,omitempty"`
	MachineName string `json:"machineName,omitempty"`
	TemplateID  string `json:"templateId,omitempty"`
	GroupID     string `json:"groupId,omitempty"`
	Datacenter  string `json:"datacenter,omitempty"`
	Region      string `json:"region,omitempty"`
}

var defaultVars = &MachineSpecVars{
	Env:         "dev",
	Username:    "kloudctl",
	Email:       "rafal+kloudctl@koding.com",
	MachineName: "kloudctl",
	Datacenter:  "sjc01",
	Region:      "us-east-1",
}

// ParseMachineSpec parses the given spec file and templates the variables
// with the given vars.
func ParseMachineSpec(file string, vars *MachineSpecVars) (*MachineSpec, error) {
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
	if vars == nil {
		vars = defaultVars
	}
	tmpl, err := template.New("spec").Funcs(vars.Funcs()).Parse(string(p))
	if err != nil {
		return nil, err
	}
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, nil); err != nil {
		return nil, err
	}
	var spec MachineSpec
	if err := json.Unmarshal(buf.Bytes(), &spec); err != nil {
		return nil, err
	}
	return &spec, nil
}

// Var a value of the given variable. If the variable is not set, it is
// going to read VAR_<NAME> env.
func (vars *MachineSpecVars) Var(name string) string {
	if s := os.Getenv("VAR_" + strings.ToUpper(name)); s != "" {
		return s
	}
	field, ok := structs.New(vars).FieldOk(name)
	if ok {
		if s, ok := field.Value().(string); ok && s != "" {
			return s
		}
	}
	return ""
}

// Funcs returns text/template funcs.
func (vars *MachineSpecVars) Funcs() map[string]interface{} {
	return map[string]interface{}{
		"var": vars.Var,
	}
}

// BuildUserAndGroup ensures the user and group of the spec are
// inserted into db.
func (spec *MachineSpec) BuildUserAndGroup(db *mongodb.MongoDB) error {
	// If MachineID is not nil, ensure it exists and reuse it if it does.
	if spec.HasMachine() {
		return db.One("jMachines", spec.Machine.ObjectId.Hex(), &spec.Machine)
	}
	// If no existing group is provided, create or use 'hackathon' one,
	// which will make VMs invisible to users until they're assigned
	// to proper group before the hackathon.
	if !spec.HasGroup() {
		group, err := getOrCreateHackathonGroup(db)
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
		err := db.Run("jUsers", query)
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
		err = db.Run("jGroups", query)
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
		var user models.User
		query := func(c *mgo.Collection) error {
			return c.FindId(spec.Machine.Users[0].Id).One(&user)
		}
		err := db.Run("jUsers", query)
		if err != nil {
			return err
		}
		spec.Machine.Users[0].Username = user.Name
	}
	// Lookup group and init Uid.
	var group models.Group
	query := func(c *mgo.Collection) error {
		return c.FindId(spec.Machine.Groups[0].Id).One(&group)
	}
	if err := db.Run("jGroups", query); err != nil {
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
func (spec *MachineSpec) BuildMachine(db *mongodb.MongoDB) error {
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
	return db.Run("jMachines", query)
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

func getOrCreateHackathonGroup(db *mongodb.MongoDB) (*models.Group, error) {
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
	if err := db.Run("jGroups", query); err != nil {
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
