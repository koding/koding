package kontrol

import (
	"koding/db/models"
	"testing"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/kite/protocol"
)

func TestFilterResult(t *testing.T) {
	kite1 := &KodingKiteWithToken{
		Kite: protocol.Kite{
			ID: "id_1",
		},
		// other fields are not used
	}

	kite2 := &KodingKiteWithToken{
		Kite: protocol.Kite{
			ID: "id_2",
		},
	}

	pastDueGroup := &models.Group{
		Id: bson.NewObjectId(),
		Payment: models.Payment{
			Subscription: models.Subscription{
				Status: "past_due",
			},
		},
	}

	activeGroup1 := &models.Group{
		Id: bson.NewObjectId(),
		Payment: models.Payment{
			Subscription: models.Subscription{
				Status: "active",
			},
		},
	}
	activeGroup2 := &models.Group{
		Id: bson.NewObjectId(),
		Payment: models.Payment{
			Subscription: models.Subscription{
				Status: "active",
			},
		},
	}

	tests := []struct {
		name                 string
		env                  string
		getKodingKitesResult *GetKodingKitesResult
		groups               []*models.Group
		kitesByGroupID       map[string][]*KodingKiteWithToken

		response *GetKodingKitesResult
	}{
		{
			name: "should stay same - everything is perfect",
			env:  "dev",
			getKodingKitesResult: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
			groups: []*models.Group{activeGroup1, activeGroup2},
			kitesByGroupID: map[string][]*KodingKiteWithToken{
				activeGroup1.Id.Hex(): {kite1, kite2},
			},
			response: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
		},
		{
			name: "remove past_due_group's kites when there is another group",
			env:  "dev",
			getKodingKitesResult: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
			groups: []*models.Group{activeGroup1, pastDueGroup},
			kitesByGroupID: map[string][]*KodingKiteWithToken{
				activeGroup1.Id.Hex(): {kite1},
				pastDueGroup.Id.Hex(): {kite2},
			},
			response: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1},
			},
		},
		{
			name: "remove past_due_group's kites when there isnt any other group",
			env:  "dev",
			getKodingKitesResult: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
			groups: []*models.Group{pastDueGroup},
			kitesByGroupID: map[string][]*KodingKiteWithToken{
				pastDueGroup.Id.Hex(): {kite2},
			},
			response: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1},
			},
		},
		{
			name: "should not remove if the group is not in  group list",
			env:  "dev",
			getKodingKitesResult: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
			groups: []*models.Group{activeGroup1},
			kitesByGroupID: map[string][]*KodingKiteWithToken{
				activeGroup1.Id.Hex(): {kite1},
				pastDueGroup.Id.Hex(): {kite2},
			},
			response: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
		},
		{
			name: "should not remove anything if there is no group",
			env:  "dev",
			getKodingKitesResult: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
			groups: []*models.Group{},
			kitesByGroupID: map[string][]*KodingKiteWithToken{
				activeGroup1.Id.Hex(): {kite1},
				pastDueGroup.Id.Hex(): {kite2},
			},
			response: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
		},
		{
			name: "should not remove anything if there is no past due group kite",
			env:  "dev",
			getKodingKitesResult: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
			groups: []*models.Group{activeGroup1, activeGroup2, pastDueGroup},
			kitesByGroupID: map[string][]*KodingKiteWithToken{
				activeGroup1.Id.Hex(): {kite1},
				activeGroup2.Id.Hex(): {kite2},
			},
			response: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
		},
		{
			name: "should not remove anything if env is default even if there is past_due group.",
			env:  "default",
			getKodingKitesResult: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
			groups: []*models.Group{activeGroup1, activeGroup2, pastDueGroup},
			kitesByGroupID: map[string][]*KodingKiteWithToken{
				activeGroup1.Id.Hex(): {kite1},
				pastDueGroup.Id.Hex(): {kite2},
			},
			response: &GetKodingKitesResult{
				Kites: []*KodingKiteWithToken{kite1, kite2},
			},
		},
	}

	for _, test := range tests {
		// capture range variable here
		// otherwise values will not be assigned correctly
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			filterRes := test.getKodingKitesResult.filter(test.env, test.groups, test.kitesByGroupID)
			if len(test.response.Kites) != len(filterRes.Kites) {
				t.Fatalf("len expected %d, got %d", len(test.response.Kites), len(filterRes.Kites))
			}

			for i := 0; i < len(test.response.Kites); i++ {
				expected := test.response.Kites[i]
				got := filterRes.Kites[i]

				if expected.Kite.ID != filterRes.Kites[i].Kite.ID {
					t.Fatalf("kite id expected %s, got %s", expected.Kite.ID, got.Kite.ID)
				}
			}
		})
	}
}
