package modelhelper_test

import (
	"math/rand"
	"testing"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	"gopkg.in/mgo.v2/bson"
)

func createGroup() (*models.Group, error) {
	g := &models.Group{
		Id:                             bson.NewObjectId(),
		Body:                           bson.NewObjectId().Hex(),
		Title:                          bson.NewObjectId().Hex(),
		Slug:                           bson.NewObjectId().Hex(),
		Privacy:                        "private",
		Visibility:                     "hidden",
		SocialApiChannelId:             "0",
		SocialApiAnnouncementChannelId: "0",
		// DefaultChannels holds the default channels for a group, when a user joins
		// to this group, participants will be automatically added to regarding
		// channels
		DefaultChannels: []string{"0"},
	}
	return g, modelhelper.CreateGroup(g)
}

func TestCreateAndGetGroup(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	rand.Seed(time.Now().UnixNano())

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
