package controller

import (
	"errors"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"time"

	"github.com/koding/logging"
	"labix.org/v2/mgo"
)

var (
	ErrMigrated     = errors.New("already migrated")
	kodingChannelId int64
)

type MigratorWorkerController struct {
	log logging.Logger
}

func NewMigratorWorkerController(log logging.Logger) (*MigratorWorkerController, error) {
	wc := &MigratorWorkerController{
		log: log,
	}

	return wc, nil
}

func (mwc *MigratorWorkerController) Start() error {
	o := modelhelper.Options{
		Sort: "meta.createdAt",
	}
	s := modelhelper.Selector{
		"socialMessageId": modelhelper.Selector{"$exists": false},
	}
	kodingChannel, err := createGroupChannel("koding", "koding")
	if err != nil {
		return fmt.Errorf("Koding channel cannot be created: %s", err)
	}
	kodingChannelId = kodingChannel.Id

	errCount := 0

	handleError := func(su *mongomodels.StatusUpdate, err error) {
		mwc.log.Error("an error occured for %s: %s", su.Id.Hex(), err)
		errCount++
	}

	for {
		o.Skip = errCount
		su, err := modelhelper.GetStatusUpdate(s, o)
		if err != nil {
			if err == mgo.ErrNotFound {
				mwc.log.Info("Migration completed")
				return nil
			}
			return fmt.Errorf("status update cannot be fetched: %s", err)
		}

		// create channel message
		cm, err := createChannelMessage(&su)
		if err != nil {
			handleError(&su, err)
			continue
		}

		// create reply messages
		cm.CreatedAt = su.Meta.CreatedAt
		cm.UpdatedAt = su.Meta.ModifiedAt
		cm.Update()

		// update mongo status update channelMessageId field
		if err := completePostMigration(&su, cm); err != nil {
			handleError(&su, err)
			continue
		}

		fmt.Printf("\n\nStatus update var %+v \n\n", su)
	}

	return nil
}

func createGroupChannel(name, groupName string) (*models.Channel, error) {
	c := models.NewChannel()
	c.Name = name
	c.GroupName = groupName
	c.TypeConstant = models.Channel_TYPE_GROUP

	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	// TODO check it causes any error
	c.PrivacyConstant = group.Privacy

	// find group owner
	creatorId, err := fetchGroupOwnerId(group)
	if err != nil {
		return nil, err
	}

	c.CreatorId = creatorId
	// create channel
	if err := c.Create(); err != nil {
		return nil, err
	}

	return c, nil
}

func fetchGroupOwnerId(g *mongomodels.Group) (int64, error) {
	// fetch owner relationship
	s := modelhelper.Selector{
		"targetName": "JAccount",
		"as":         "owner",
		"sourceId":   g.Id,
	}
	r, err := modelhelper.GetRelationship(s)
	if err != nil {
		return 0, err
	}

	a := models.NewAccount()
	a.OldId = r.TargetId.Hex()
	if err := a.FetchOrCreate(); err != nil {
		return 0, err
	}

	return a.Id, nil
}

func createChannelMessage(su *mongomodels.StatusUpdate) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Slug = su.Slug
	cm.Body = su.Body
	cm.TypeConstant = models.ChannelMessage_TYPE_POST
	// cm.CreatedAt = su.Meta.CreatedAt
	cm.CreatedAt = time.Now().Add(-48 * time.Hour)
	cm.UpdatedAt = su.Meta.ModifiedAt

	if err := prepareMessageAccount(cm, su); err != nil {
		return nil, err
	}

	if err := prepareMessageChannel(cm, su); err != nil {
		return nil, err
	}

	if err := cm.CreateRaw(); err != nil {
		return nil, err
	}

	return cm, nil
}

func prepareMessageAccount(cm *models.ChannelMessage, su *mongomodels.StatusUpdate) error {
	a := models.NewAccount()
	a.OldId = su.OriginId.Hex()
	if err := a.FetchOrCreate(); err != nil {
		return fmt.Errorf("account could not found: %s", err)
	}

	cm.AccountId = a.Id

	return nil
}

func prepareMessageChannel(cm *models.ChannelMessage, su *mongomodels.StatusUpdate) error {
	// koding group channel id is prefetched
	if su.Group == "koding" {
		cm.InitialChannelId = kodingChannelId
		return nil
	}

	c, err := createGroupChannel(su.Group, su.Group)
	if err != nil {
		return err
	}
	cm.InitialChannelId = c.Id

	return nil
}

func completePostMigration(su *mongomodels.StatusUpdate, cm *models.ChannelMessage) error {
	su.SocialMessageId = cm.Id

	return modelhelper.UpdateStatusUpdate(su)
}
