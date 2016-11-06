package machine

import (
	"reflect"
	"testing"
	"time"
)

func TestMongoDatabaseFix1(t *testing.T) {
	tests := []struct {
		Name     string
		Filter   *Filter
		IsValid  bool
		Machines []*Machine
	}{
		{
			Name: "bober machine list",
			Filter: &Filter{
				Username:     "bober",
				Owners:       true,
				OnlyApproved: true,
			},
			IsValid: true,
			Machines: []*Machine{
				&Machine{
					Team:      "orange",
					Stack:     "boberStack",
					Provider:  "aws",
					Label:     "bober-aws-0",
					IP:        "127.0.0.1",
					CreatedAt: time.Date(2016, 1, 1, 0, 0, 0, 0, time.UTC),
					Status: MachineStatus{
						State:      "running",
						Reason:     "because it can",
						ModifiedAt: time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC),
					},
					Users: []MachineUser{
						{
							Sudo:     true,
							Owner:    true,
							Username: "bober",
						},
					},
				},
				&Machine{
					Team:  "orange",
					Stack: "boberStack",
					Label: "bober-aws-1",
					Users: []MachineUser{
						{
							Sudo:     true,
							Owner:    true,
							Username: "bober",
						},
					},
				},
				&Machine{
					Team:  "orange",
					Stack: "johnStack",
					Label: "john-google-0",
					Users: []MachineUser{
						{
							Sudo:     true,
							Owner:    true,
							Username: "john",
						},
						{
							Approved: true,
							Username: "bober",
						},
					},
				},
			},
		},
		{
			Name: "john machine list",
			Filter: &Filter{
				Username:     "john",
				Owners:       true,
				OnlyApproved: true,
			},
			IsValid: true,
			Machines: []*Machine{
				&Machine{
					Team:  "orange",
					Stack: "boberStack",
					Label: "bober-aws-1",
					Users: []MachineUser{
						{
							Sudo:     true,
							Owner:    true,
							Username: "bober",
						},
						{
							Approved: true,
							Username: "john",
						},
					},
				},
				&Machine{
					Team:  "orange",
					Stack: "johnStack",
					Label: "john-google-0",
					Users: []MachineUser{
						{
							Sudo:     true,
							Owner:    true,
							Username: "john",
						},
					},
				},
			},
		},
		{
			Name: "blaster machine list",
			Filter: &Filter{
				Username:     "blaster",
				Owners:       true,
				OnlyApproved: true,
			},
			IsValid: true,
			Machines: []*Machine{
				&Machine{
					Team:  "orange",
					Stack: "boberStack",
					Label: "bober-aws-1",
					Users: []MachineUser{
						{
							Sudo:     true,
							Owner:    true,
							Username: "bober",
						},
						{
							Approved: true,
							Username: "blaster",
						},
					},
				},
				&Machine{
					Team:  "orange",
					Stack: "blasterStack",
					Label: "blaster-aws-0",
					Users: []MachineUser{
						{
							Sudo:     true,
							Owner:    true,
							Username: "blaster",
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

	mongoDB := MongoDatabase{adapter: Fix1}
	for _, test := range tests {
		t.Run(test.Name, func(t *testing.T) {
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
