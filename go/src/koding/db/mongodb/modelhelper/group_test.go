package modelhelper_test

import (
	"math/rand"
	"testing"
	"time"

	"github.com/koding/kite/protocol"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	"gopkg.in/mgo.v2/bson"
)

func createGroup() (*models.Group, error) {
	g := &models.Group{
		Id:                 bson.NewObjectId(),
		Body:               bson.NewObjectId().Hex(),
		Title:              bson.NewObjectId().Hex(),
		Slug:               bson.NewObjectId().Hex(),
		Privacy:            "private",
		Visibility:         "hidden",
		SocialApiChannelId: "0",
		// DefaultChannels holds the default channels for a group, when a user joins
		// to this group, participants will be automatically added to regarding
		// channels
		DefaultChannels: []string{"0"},
	}
	return g, modelhelper.CreateGroup(g)
}

func createGroups(n int) ([]*models.Group, error) {
	groups := make([]*models.Group, n)

	for i := range groups {
		g, err := createGroup()
		if err != nil {
			return nil, err
		}

		groups[i] = g
	}

	return groups, nil
}

func init() {
	rand.Seed(time.Now().UnixNano())
}

func TestCreateAndGetGroup(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	g, err := createGroup()
	if err != nil {
		t.Fatalf(err.Error())
	}

	g2, err := modelhelper.GetGroup(g.Slug)
	if err != nil {
		t.Errorf(err.Error())
	}

	if g2 == nil {
		t.Errorf("couldnt fetch group by its slug. Got nil, expected: %+v", g)
	}

	if g2.Id.Hex() != g.Id.Hex() {
		t.Errorf("groups are not same: expected: %+v, got: %+v ", g.Id.Hex(), g2.Id.Hex())
	}

	randomName := bson.NewObjectId().Hex()
	_, err = modelhelper.GetGroup(randomName)
	if err == nil {
		t.Errorf("we should not be able to find the group")
	}
}

func mustKiteID(queryString string) string {
	k, err := protocol.KiteFromString(queryString)
	if err != nil {
		panic("mustKiteID: " + err.Error())
	}

	return k.ID
}

func TestLookupGroup(t *testing.T) {
	const N = 10

	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	user, _, err := modeltesthelper.CreateUser(bson.NewObjectId().Hex())
	if err != nil {
		t.Fatalf("CreateUser()=%s", err)
	}

	groups, err := createGroups(N + 1)
	if err != nil {
		t.Fatalf("createGroups()=%s", err)
	}

	machines, err := createMachines(N, t)
	if err != nil {
		t.Fatalf("createMachines()=%s", err)
	}

	for i := range machines {
		machines[i].Groups = []models.MachineGroup{{Id: groups[i].Id}}

		update := bson.M{
			"$set": bson.M{
				"groups": machines[i].Groups,
				"users": []*models.MachineUser{{
					Id:       user.ObjectId,
					Username: user.Name,
				}},
			},
		}

		if i&2 == 0 {
			// force to lookup by registerUrl for machines with even index
			update["$set"].(bson.M)["ipAddress"] = ""
		}

		err := modelhelper.UpdateMachine(machines[i].ObjectId, update)
		if err != nil {
			t.Fatalf("UpdateMachine()=%s", err)
		}
	}

	session := &models.Session{
		Id:        bson.NewObjectId(),
		GroupName: groups[N].Slug,
		Username:  user.Name,
	}

	if err := modelhelper.CreateSession(session); err != nil {
		t.Fatalf("CreateSession()=%s")
	}

	cases := map[string]struct {
		opts *modelhelper.LookupGroupOptions
		id   bson.ObjectId
	}{
		"lookup by queryString": {
			&modelhelper.LookupGroupOptions{
				Username: user.Name,
				KiteID:   mustKiteID(machines[0].QueryString),
			},
			groups[0].Id,
		},
		"lookup by ipAddress": {
			&modelhelper.LookupGroupOptions{
				Username:  user.Name,
				ClientURL: machines[1].RegisterURL,
			},
			groups[1].Id,
		},
		"lookup by registerUrl": {
			&modelhelper.LookupGroupOptions{
				Username:  user.Name,
				ClientURL: machines[4].RegisterURL,
			},
			groups[4].Id,
		},
		"lookup by most recent session for KD": {
			&modelhelper.LookupGroupOptions{
				Username:    user.Name,
				Environment: "managed",
			},
			groups[N].Id,
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			team, err := modelhelper.LookupGroup(cas.opts)
			if err != nil {
				t.Fatalf("LookupGroup()=%s", err)
			}

			if team.Id != cas.id {
				t.Fatalf("got %q, want %q", team.Id.Hex(), cas.id.Hex())
			}
		})
	}
}
