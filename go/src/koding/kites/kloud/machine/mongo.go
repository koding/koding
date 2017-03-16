package machine

import (
	"errors"
	"net"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2/bson"
)

// adapter is a private interface used as an adapter for database mongo
// singleton. This allows to mock database and create reproducible tests for
// MongoDatabase logic.
type adapter interface {
	// GetMachineByID gets a machine by its ID.
	GetMachineByID(string) (*models.Machine, error)

	// GetParticipatedMachinesByUsername gets all machines which are accessible to
	// provided user.
	GetParticipatedMachinesByUsername(string) ([]*models.Machine, error)

	// GetStackTemplateFieldsByIds retrieves a slice of stack templates matching
	// the given ids and limited to the specified fields.
	GetStackTemplateFieldsByIds([]bson.ObjectId, []string) ([]*models.StackTemplate, error)
}

// MongoDatabase implements Database interface. This type is responsible for
// communicating with Mongo database.
type MongoDatabase struct {
	adapter adapter
}

var _ Database = (*MongoDatabase)(nil)

// NewMongoDatabase creates a new MongoDatabase instance.
func NewMongoDatabase() *MongoDatabase {
	return &MongoDatabase{
		adapter: modelHelper, // use modelhelper package's singleton.
	}
}

// Machines returns all machines stored in MongoDB database that matches a given
// filter.
func (m *MongoDatabase) Machines(f *Filter) ([]*Machine, error) {
	if m.adapter == nil {
		return nil, errors.New("database adapter is unavailable")
	}

	if f == nil {
		return nil, errors.New("machine filter is not set")
	}

	if f.Username == "" {
		return nil, errors.New("machine requires user name to be provided")
	}

	var machinesDB []*models.Machine

	if f.ID != "" {
		machine, err := m.adapter.GetMachineByID(f.ID)
		if err != nil {
			return nil, models.ResError(err, modelhelper.MachinesColl)
		}

		machinesDB = append(machinesDB, machine)
	} else {
		// Get all machines that can be seen by provided user. This also includes
		// shared machines.
		var err error
		machinesDB, err = m.adapter.GetParticipatedMachinesByUsername(f.Username)
		if err != nil {
			return nil, models.ResError(err, modelhelper.MachinesColl)
		}
	}

	// We do not need machines from koding solo(koding provider) so, skip them.
	for i := 0; i < len(machinesDB); i++ {
		if machinesDB[i].Provider == modelhelper.MachineProviderKoding {
			machinesDB = append(machinesDB[:i], machinesDB[i+1:]...)
			i--
		}
	}

	// Leave only shared machines that user approved.
	if f.OnlyApproved {
		for i := 0; i < len(machinesDB); i++ {
			for j := range machinesDB[i].Users {
				if machinesDB[i].Users[j].Username == f.Username && // user of machine
					!machinesDB[i].Users[j].Owner && // and not an owner
					!machinesDB[i].Users[j].Approved { // who didn't approve sharing.
					machinesDB = append(machinesDB[:i], machinesDB[i+1:]...)
					i--
				}
			}
		}
	}

	// Get stack template IDs used by machines. Using map as the storage will
	// remove duplicated values.
	stackTmplIDs := make(map[bson.ObjectId]struct{})
	for i := range machinesDB {
		if machinesDB[i].GeneratedFrom != nil {
			stackTmplIDs[machinesDB[i].GeneratedFrom.TemplateId] = struct{}{}
		}
	}

	// We don't need to search in jGroups collection in order to find team name
	// because jStackTemplates also contains that information.
	stackTmplsDB, err := m.adapter.GetStackTemplateFieldsByIds(
		toSlice(stackTmplIDs),             // stack templates to find.
		[]string{"_id", "group", "title"}, // fields we need from jStackTemplates.
	)
	if err != nil {
		return nil, models.ResError(err, modelhelper.StackTemplateColl)
	}

	// Helper made to simplify searching for group and title names.
	groupTitles := make(map[bson.ObjectId][2]string, len(stackTmplsDB))
	for _, st := range stackTmplsDB {
		groupTitles[st.Id] = [2]string{st.Group, st.Title}
	}

	machines := make([]*Machine, len(machinesDB))
	for i, mdb := range machinesDB {
		machines[i] = &Machine{
			ID:          mdb.ObjectId.Hex(),
			Provider:    mdb.Provider,
			Label:       mdb.Label,
			IP:          hostOnly(mdb.IpAddress),
			QueryString: mdb.QueryString,
			RegisterURL: mdb.RegisterURL,
			CreatedAt:   mdb.CreatedAt,
			Status: Status{
				State:      mdb.Status.State,
				Reason:     mdb.Status.Reason,
				ModifiedAt: mdb.Status.ModifiedAt,
			},
			Users: filterUsers(mdb.Users, f),
		}

		if mdb.GeneratedFrom != nil {
			machines[i].Team = groupTitles[mdb.GeneratedFrom.TemplateId][0]
			machines[i].Stack = groupTitles[mdb.GeneratedFrom.TemplateId][1]
		}
	}

	return machines, nil
}

// toSlice is a helper function that converts bson.ObjectId set to slice.
func toSlice(set map[bson.ObjectId]struct{}) (s []bson.ObjectId) {
	for objID := range set {
		s = append(s, objID)
	}
	return s
}

// makeMachineUser converts machine users from model to MachineUser object.
// We have separate MachineUser type here to not propagate internal
// bson.ObjectId value outside the back-end.
func makeMachineUser(mu *models.MachineUser) User {
	return User{
		Sudo:      mu.Sudo,
		Owner:     mu.Owner,
		Permanent: mu.Permanent,
		Approved:  mu.Approved,
		Username:  mu.Username,
	}
}

// filterUsers removes users specified by provided filter. This prevents from
// receiving possibly sensitive information about machine users.
func filterUsers(users []models.MachineUser, f *Filter) (res []User) {
	for i := range users {
		// Filter by user name.
		if f.Username != "" && users[i].Username == f.Username {
			res = append(res, makeMachineUser(&users[i]))
			continue
		}

		// Keep machine owners in order to know who shared his machine with us.
		if f.Owners && users[i].Owner && users[i].Sudo {
			res = append(res, makeMachineUser(&users[i]))
			continue
		}
	}

	return
}

// hostOnly returns only host part of provided address. This is a fix for
// machine IpAddress field which contains klient's port. Following bug is
// already fixed, however some of jMachines documents may still have invalid
// value. Remove this function when you are sure that there are no buggy
// entries in db.
func hostOnly(hostport string) string {
	host, _, err := net.SplitHostPort(hostport)
	if err != nil {
		return hostport
	}

	return host
}
