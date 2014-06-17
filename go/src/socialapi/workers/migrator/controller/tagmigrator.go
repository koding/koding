package controller

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"

	"github.com/jinzhu/gorm"
	"labix.org/v2/mgo/bson"
)

func (mwc *Controller) migrateAllTags() error {
	o := modelhelper.Options{
		Sort: "meta.createdAt",
	}
	s := modelhelper.Selector{
		"socialApiChannelId": modelhelper.Selector{"$exists": false},
	}
	errCount := 0
	successCount := 0

	handleError := func(t *mongomodels.Tag, err error) {
		mwc.log.Error("an error occured for tag %s: %s", t.Id.Hex(), err)
		errCount++
	}

	iter := modelhelper.GetTagIter(s, o)
	var tag mongomodels.Tag
	for iter.Next(&tag) {
		channelId, err := createTagChannel(&tag)
		if err != nil {
			handleError(&tag, err)
			continue
		}
		if err := mwc.createTagFollowers(&tag, channelId); err != nil {
			handleError(&tag, err)
			continue
		}

		if err := completeTagMigration(&tag, channelId); err != nil {
			handleError(&tag, err)
			continue
		}
		successCount++
	}

	if err := iter.Err(); err != nil {
		return fmt.Errorf("Tag migration is interrupted with %d errors: %s", errCount, err)
	}

	mwc.log.Notice("Tag migration completed for %d tags with %d errors", successCount, errCount)

	return nil
}

func createTagChannel(t *mongomodels.Tag) (int64, error) {
	creatorId, err := fetchTagCreatorId(t)
	if err != nil {
		return 0, err
	}

	c := models.NewChannel()

	channelId, err := c.FetchChannelIdByNameAndGroupName(t.Slug, t.Group)
	if err == nil {
		return channelId, nil
	}
	if err != gorm.RecordNotFound {
		return 0, err
	}

	c.CreatorId = creatorId
	c.Name = t.Slug
	c.GroupName = t.Group // create group if needed
	c.Purpose = "Channel for " + c.Name + " topic"
	c.TypeConstant = models.Channel_TYPE_TOPIC
	c.PrivacyConstant = models.Channel_PRIVACY_PRIVATE
	c.CreatedAt = t.Meta.CreatedAt
	c.UpdatedAt = t.Meta.ModifiedAt
	if err := c.CreateRaw(); err != nil {
		return 0, err
	}

	return c.Id, nil
}

func fetchTagCreatorId(t *mongomodels.Tag) (int64, error) {
	s := modelhelper.Selector{
		"sourceId": t.Id,
		"as":       "related",
	}
	r, err := modelhelper.GetRelationship(s)
	if err != nil {
		return 0, fmt.Errorf("Tag creator cannot be fetched: %s", err)
	}
	id, err := models.AccountIdByOldId(r.TargetId.Hex(), "")
	if err != nil {
		return 0, fmt.Errorf("Tag creator cannot be created: %s", err)
	}

	return id, nil
}

func (mwc *Controller) createTagFollowers(t *mongomodels.Tag, channelId int64) error {
	s := modelhelper.Selector{
		"sourceId":   t.Id,
		"as":         "follower",
		"targetName": "JAccount",
	}

	return mwc.createChannelParticipants(s, channelId)
}

func (mwc *Controller) createChannelParticipants(s modelhelper.Selector, channelId int64) error {
	iter := modelhelper.GetRelationshipIter(s)
	defer iter.Close()
	var r mongomodels.Relationship
	for iter.Next(&r) {
		if r.MigrationStatus == "Completed" {
			continue
		}
		// fetch follower
		id, err := models.AccountIdByOldId(r.TargetId.Hex(), "")
		if err != nil {
			mwc.log.Error("Participant account cannot be fetched: %s", err)
			continue
		}

		cp := models.NewChannelParticipant()
		cp.ChannelId = channelId
		cp.AccountId = id
		cp.StatusConstant = models.ChannelParticipant_STATUS_ACTIVE
		cp.LastSeenAt = r.TimeStamp
		cp.UpdatedAt = r.TimeStamp
		cp.CreatedAt = r.TimeStamp
		if err := cp.CreateRaw(); err != nil {
			mwc.log.Error("Participant cannot be created: %s", err)
			continue
		}

		r.MigrationStatus = "Completed"
		if err := modelhelper.UpdateRelationship(&r); err != nil {
			mwc.log.Error("Participant relationship cannot be flagged as migrated: %s", err)
		}
	}

	return iter.Err()
}

func (mwc *Controller) migrateTags(cm *models.ChannelMessage, oldId bson.ObjectId) error {
	s := modelhelper.Selector{
		"sourceId":   oldId,
		"as":         "tag",
		"targetName": "JTag",
	}
	rels, err := modelhelper.GetAllRelationships(s)
	if err != nil {
		return fmt.Errorf("tags cannot be fetched: %s", err)
	}
	for _, r := range rels {
		t, err := modelhelper.GetTagById(r.TargetId.Hex())
		if err != nil {
			mwc.log.Error("tag cannot be fetched: %s", err)
			continue
		}

		cml := models.NewChannelMessageList()
		cml.ChannelId = t.SocialApiChannelId
		cml.MessageId = cm.Id
		cml.AddedAt = cm.CreatedAt
		if err := cml.CreateRaw(); err != nil {
			mwc.log.Error("message tag cannot be created")
		}
	}

	return nil
}

func completeTagMigration(tag *mongomodels.Tag, channelId int64) error {
	tag.SocialApiChannelId = channelId

	return modelhelper.UpdateTag(tag)
}
