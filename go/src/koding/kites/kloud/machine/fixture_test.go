package machine

import (
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// fixture is a mock for MongoDB tables.
type fixture struct {
	MachineColl       []*models.Machine       // machines collection.
	StackTemplateColl []*models.StackTemplate // stack template collection.
}

var _ adapter = (*fixture)(nil)

// GetMachinesByUsername mocks GetMachinesByUsername method.
func (f *fixture) GetMachinesByUsername(username string) (ms []*models.Machine, err error) {
	for _, m := range f.MachineColl {
		for _, u := range m.Users {
			if u.Username == username {
				ms = append(ms, m)
				break
			}
		}
	}

	if len(ms) == 0 {
		return nil, mgo.ErrNotFound
	}

	return ms, nil
}

// GetStackTemplateFieldsByIds mocks GetStackTemplateFieldsByIds method.
func (f *fixture) GetStackTemplateFieldsByIds(ids []bson.ObjectId, _ []string) (sts []*models.StackTemplate, err error) {
	for _, st := range f.StackTemplateColl {
		for _, id := range ids {
			if id == st.Id {
				sts = append(sts, st)
				break
			}
		}
	}

	if len(sts) == 0 {
		return nil, mgo.ErrNotFound
	}

	return sts, nil
}

// Fix1 describes the following database state:
//
// Team: orange,
// Users:
//   - bober:
//      - bober-aws-0, stack: boberStack, admin.
//      - bober-aws-1, stack: boberStack, admin, shared with: john, blaster.
//   - john:
//      - john-google-0, stack: johnStack, shared with: bober, blaster(not approved).
//   - blaster:
//      - blaster-aws-0, stack: blasterStack.
//      - instance from koding provider.
//
var Fix1 = &fixture{
	MachineColl: []*models.Machine{
		&models.Machine{
			ObjectId:  "boberMachine1_ID",
			IpAddress: "127.0.0.1:56789",
			Provider:  "aws",
			Label:     "bober-aws-0",
			Users: []models.MachineUser{
				{
					Sudo:     true,
					Owner:    true,
					Username: "bober",
				},
			},
			CreatedAt: time.Date(2016, 1, 1, 0, 0, 0, 0, time.UTC),
			Status: models.MachineStatus{
				State:      "running",
				Reason:     "because it can",
				ModifiedAt: time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC),
			},
			GeneratedFrom: models.MachineGeneratedFrom{
				TemplateId: "boberStack_ID",
			},
		},
		&models.Machine{
			ObjectId: "boberMachine2_ID",
			Label:    "bober-aws-1",
			Users: []models.MachineUser{
				{
					Sudo:     true,
					Owner:    true,
					Username: "bober",
				},
				{
					Approved: true,
					Username: "john",
				},
				{
					Approved: true,
					Username: "blaster",
				},
			},
			GeneratedFrom: models.MachineGeneratedFrom{
				TemplateId: "boberStack_ID",
			},
		},
		&models.Machine{
			ObjectId: "johnMachine1_ID",
			Label:    "john-google-0",
			Users: []models.MachineUser{
				{
					Sudo:     true,
					Owner:    true,
					Username: "john",
				},
				{
					Approved: true,
					Username: "bober",
				},
				{
					Username: "blaster",
				},
			},
			GeneratedFrom: models.MachineGeneratedFrom{
				TemplateId: "johnStack_ID",
			},
		},
		&models.Machine{
			ObjectId: "blasterMachine1_ID",
			Label:    "blaster-aws-0",
			Users: []models.MachineUser{
				{
					Sudo:     true,
					Owner:    true,
					Username: "blaster",
				},
			},
			GeneratedFrom: models.MachineGeneratedFrom{
				TemplateId: "blasterStack_ID",
			},
		},
		&models.Machine{
			Provider: modelhelper.MachineProviderKoding,
			Users: []models.MachineUser{
				{
					Sudo:     true,
					Owner:    true,
					Username: "blaster",
				},
			},
		},
	},
	StackTemplateColl: []*models.StackTemplate{
		&models.StackTemplate{
			Id:    "boberStack_ID",
			Group: "orange",
			Title: "boberStack",
		},
		&models.StackTemplate{
			Id:    "johnStack_ID",
			Group: "orange",
			Title: "johnStack",
		},
		&models.StackTemplate{
			Id:    "blasterStack_ID",
			Group: "orange",
			Title: "blasterStack",
		},
	},
}
