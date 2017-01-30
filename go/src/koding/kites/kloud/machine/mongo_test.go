package machine

import (
	"reflect"
	"testing"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	"gopkg.in/mgo.v2/bson"
)

// User names.
var (
	bober   = bson.NewObjectId().Hex()
	john    = bson.NewObjectId().Hex()
	blaster = bson.NewObjectId().Hex()
)

// Stack template names.
var (
	boberStack   = bson.NewObjectId()
	johnStack    = bson.NewObjectId()
	blasterStack = bson.NewObjectId()
)

// Machine IDs.
var (
	boberAws0   = bson.NewObjectId()
	boberAws1   = bson.NewObjectId()
	johnGoogle0 = bson.NewObjectId()
	blasterAws0 = bson.NewObjectId()
	allKoding0  = bson.NewObjectId()
)

func prepareMongoMachines() error {
	userIDs := map[string]bson.ObjectId{}
	for _, u := range []string{bober, john, blaster} {
		user, _, err := modeltesthelper.CreateUser(u)
		if err != nil {
			return err
		}
		userIDs[u] = user.ObjectId
	}

	machines := []*models.Machine{
		{
			ObjectId:  boberAws0,
			IpAddress: "127.0.0.1",
			Provider:  "aws",
			Label:     "bober-aws-0",
			Users: []models.MachineUser{
				{
					Id:       userIDs[bober],
					Sudo:     true,
					Owner:    true,
					Username: bober,
				},
			},
			Status: models.MachineStatus{
				State:  "running",
				Reason: "because it can",
			},
			GeneratedFrom: &models.MachineGeneratedFrom{
				TemplateId: boberStack,
			},
		},
		{
			ObjectId: boberAws1,
			Label:    "bober-aws-1",
			Users: []models.MachineUser{
				{
					Id:       userIDs[bober],
					Sudo:     true,
					Owner:    true,
					Username: bober,
				},
				{
					Id:       userIDs[john],
					Approved: true,
					Username: john,
				},
				{
					Id:       userIDs[blaster],
					Approved: true,
					Username: blaster,
				},
			},
			GeneratedFrom: &models.MachineGeneratedFrom{
				TemplateId: boberStack,
			},
		},
		{
			ObjectId: johnGoogle0,
			Label:    "john-google-0",
			Users: []models.MachineUser{
				{
					Id:       userIDs[john],
					Sudo:     true,
					Owner:    true,
					Username: john,
				},
				{
					Id:       userIDs[bober],
					Approved: true,
					Username: bober,
				},
				{
					Id:       userIDs[blaster],
					Username: blaster,
				},
			},
			GeneratedFrom: &models.MachineGeneratedFrom{
				TemplateId: johnStack,
			},
		},
		{
			ObjectId: blasterAws0,
			Label:    "blaster-aws-0",
			Users: []models.MachineUser{
				{
					Id:       userIDs[blaster],
					Sudo:     true,
					Owner:    true,
					Username: blaster,
				},
			},
			GeneratedFrom: &models.MachineGeneratedFrom{
				TemplateId: blasterStack,
			},
		},
		{
			ObjectId: allKoding0,
			Provider: modelhelper.MachineProviderKoding,
			Users: []models.MachineUser{
				{
					Id:       userIDs[blaster],
					Sudo:     true,
					Owner:    true,
					Username: blaster,
				},
			},
		},
	}

	for _, m := range machines {
		if err := modelhelper.CreateMachine(m); err != nil {
			return err
		}
	}

	return nil
}

func prepareMongoStackTmpls() error {
	stackTmpls := []*models.StackTemplate{
		{
			Id:       boberStack,
			Group:    "orange",
			Title:    "boberStack",
			OriginID: bson.NewObjectId(),
		},
		{
			Id:       johnStack,
			Group:    "orange",
			Title:    "johnStack",
			OriginID: bson.NewObjectId(),
		},
		{
			Id:       blasterStack,
			Group:    "orange",
			Title:    "blasterStack",
			OriginID: bson.NewObjectId(),
		},
	}

	for _, st := range stackTmpls {
		if err := modelhelper.CreateStackTemplate(st); err != nil {
			return err
		}
	}

	return nil
}

func TestMongoDatabase(t *testing.T) {
	tests := []struct {
		Name     string
		Filter   *Filter
		IsValid  bool
		Machines []*Machine
	}{
		{
			Name: "bober machine list",
			Filter: &Filter{
				Username:     bober,
				Owners:       true,
				OnlyApproved: true,
			},
			IsValid: true,
			Machines: []*Machine{
				{
					ID:       boberAws0.Hex(),
					Team:     "orange",
					Stack:    "boberStack",
					Provider: "aws",
					Label:    "bober-aws-0",
					IP:       "127.0.0.1",
					Status: Status{
						State:  "running",
						Reason: "because it can",
					},
					Users: []User{
						{
							Sudo:     true,
							Owner:    true,
							Username: bober,
						},
					},
				},
				{
					ID:    boberAws1.Hex(),
					Team:  "orange",
					Stack: "boberStack",
					Label: "bober-aws-1",
					Users: []User{
						{
							Sudo:     true,
							Owner:    true,
							Username: bober,
						},
					},
				},
				{
					ID:    johnGoogle0.Hex(),
					Team:  "orange",
					Stack: "johnStack",
					Label: "john-google-0",
					Users: []User{
						{
							Sudo:     true,
							Owner:    true,
							Username: john,
						},
						{
							Approved: true,
							Username: bober,
						},
					},
				},
			},
		},
		{
			Name: "john machine list",
			Filter: &Filter{
				Username:     john,
				Owners:       true,
				OnlyApproved: true,
			},
			IsValid: true,
			Machines: []*Machine{
				{
					ID:    boberAws1.Hex(),
					Team:  "orange",
					Stack: "boberStack",
					Label: "bober-aws-1",
					Users: []User{
						{
							Sudo:     true,
							Owner:    true,
							Username: bober,
						},
						{
							Approved: true,
							Username: john,
						},
					},
				},
				{
					ID:    johnGoogle0.Hex(),
					Team:  "orange",
					Stack: "johnStack",
					Label: "john-google-0",
					Users: []User{
						{
							Sudo:     true,
							Owner:    true,
							Username: john,
						},
					},
				},
			},
		},
		{
			Name: "blaster machine list",
			Filter: &Filter{
				Username:     blaster,
				Owners:       true,
				OnlyApproved: true,
			},
			IsValid: true,
			Machines: []*Machine{
				{
					ID:    boberAws1.Hex(),
					Team:  "orange",
					Stack: "boberStack",
					Label: "bober-aws-1",
					Users: []User{
						{
							Sudo:     true,
							Owner:    true,
							Username: bober,
						},
						{
							Approved: true,
							Username: blaster,
						},
					},
				},
				{
					ID:    blasterAws0.Hex(),
					Team:  "orange",
					Stack: "blasterStack",
					Label: "blaster-aws-0",
					Users: []User{
						{
							Sudo:     true,
							Owner:    true,
							Username: blaster,
						},
					},
				},
			},
		},
		{
			Name: "unknown user machine list",
			Filter: &Filter{
				Username:     "unknown",
				Owners:       true,
				OnlyApproved: true,
			},
			IsValid:  false,
			Machines: nil,
		},
	}

	// Prepare database.
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	if err := prepareMongoMachines(); err != nil {
		t.Fatalf("want err == nil; got %v", err)
	}

	if err := prepareMongoStackTmpls(); err != nil {
		t.Fatalf("want err == nil; got %v", err)
	}

	mongoDB := NewMongoDatabase()
	for _, test := range tests {
		// capture range variable here
		test := test
		t.Run(test.Name, func(t *testing.T) {
			t.Parallel()
			machines, err := mongoDB.Machines(test.Filter)
			if (err == nil) != test.IsValid {
				t.Fatalf("want valid test = %t; got err: %v", test.IsValid, err)
			}

			if len(machines) != len(test.Machines) {
				t.Fatalf("want slice length = %d; got %d", len(test.Machines), len(machines))
			}

			for i := range test.Machines {
				if !reflect.DeepEqual(machines[i], test.Machines[i]) {
					t.Fatalf("want machine[%d] = \n%# v\ngot:\n%# v\n", i, test.Machines[i], machines[i])
				}
			}
		})
	}
}
