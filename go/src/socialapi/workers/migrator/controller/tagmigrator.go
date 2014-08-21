package controller

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"socialapi/models"
	"strings"

	verbalexpressions "github.com/VerbalExpressions/GoVerbalExpressions"
	"github.com/koding/bongo"
	"labix.org/v2/mgo/bson"
)

func (mwc *Controller) migrateAllTags() error {
	mwc.log.Notice("Tag migration started")
	s := modelhelper.Selector{
		"socialApiChannelId": modelhelper.Selector{"$exists": false},
	}
	errCount := 0
	successCount := 0

	handleError := func(t *mongomodels.Tag, err error) {
		mwc.log.Error("an error occured for tag %s: %s", t.Id.Hex(), err)
		errCount++

		s := modelhelper.Selector{"_id": t.Id}
		o := modelhelper.Selector{"$set": modelhelper.Selector{"socialApiChannelId": -1, "error": err.Error()}}
		if err := modelhelper.UpdateTagPartial(s, o); err != nil {
			mwc.log.Warning("Could not update tag document: %s", err)
		}
	}

	migrateTag := func(tag interface{}) error {
		oldTag := tag.(*mongomodels.Tag)
		channelId, err := mwc.createTagChannel(oldTag)
		if err != nil {
			handleError(oldTag, err)
			return nil
		}
		if err := mwc.createTagFollowers(oldTag, channelId); err != nil {
			handleError(oldTag, err)
			return nil
		}

		if err := completeTagMigration(oldTag, channelId); err != nil {
			handleError(oldTag, err)
			return nil
		}
		successCount++

		return nil
	}

	iterOptions := helpers.NewIterOptions()
	iterOptions.CollectionName = "jTags"
	iterOptions.F = migrateTag
	iterOptions.Filter = s
	iterOptions.Result = &mongomodels.Tag{}
	iterOptions.Limit = 10000000
	iterOptions.Skip = 0

	helpers.Iter(modelhelper.Mongo, iterOptions)

	mwc.log.Notice("Tag migration completed for %d tags with %d errors", successCount, errCount)

	return nil
}

func (mwc *Controller) createTagChannel(t *mongomodels.Tag) (int64, error) {
	creatorId, err := mwc.fetchTagCreatorId(t)
	if err != nil {
		return 0, err
	}

	c := models.NewChannel()

	channelId, err := c.FetchChannelIdByNameAndGroupName(t.Slug, t.Group)
	if err == nil {
		return channelId, nil
	}
	if err != bongo.RecordNotFound {
		return 0, err
	}

	c.CreatorId = creatorId
	c.Name = t.Slug
	c.GroupName = t.Group // create group if needed
	c.Purpose = "Channel for " + c.Name + " topic"
	c.TypeConstant = models.Channel_TYPE_TOPIC
	c.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
	c.CreatedAt = t.Meta.CreatedAt
	c.UpdatedAt = t.Meta.ModifiedAt
	if err := c.CreateRaw(); err != nil {
		return 0, err
	}

	return c.Id, nil
}

func (mwc *Controller) fetchTagCreatorId(t *mongomodels.Tag) (int64, error) {
	s := modelhelper.Selector{
		"sourceId": t.Id,
		"as":       "related",
	}
	r, err := modelhelper.GetRelationship(s)
	if err != nil {
		return 0, fmt.Errorf("Tag creator cannot be fetched: %s", err)
	}

	return mwc.AccountIdByOldId(r.TargetId.Hex())
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

	migrateRelationship := func(relationship interface{}) error {
		r := relationship.(*mongomodels.Relationship)

		if r.MigrationStatus == "Completed" {
			return nil
		}
		// fetch follower
		id, err := mwc.AccountIdByOldId(r.TargetId.Hex())
		if err != nil {
			mwc.log.Error("Participant account %s cannot be fetched: %s", r.TargetId.Hex(), err)
			return nil
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
			return nil
		}

		r.MigrationStatus = "Completed"
		if err := modelhelper.UpdateRelationship(r); err != nil {
			mwc.log.Error("Participant relationship cannot be flagged as migrated: %s", err)
		}

		return nil
	}

	iterOptions := helpers.NewIterOptions()
	iterOptions.CollectionName = "relationships"
	iterOptions.F = migrateRelationship
	iterOptions.Filter = s
	iterOptions.Result = &mongomodels.Relationship{}
	iterOptions.Limit = 1000000000
	iterOptions.Skip = 0

	return helpers.Iter(modelhelper.Mongo, iterOptions)
}

func (mwc *Controller) migrateTags(cm *models.ChannelMessage, oldId bson.ObjectId) error {
	s := modelhelper.Selector{
		"sourceId":   oldId,
		"as":         "tag",
		"targetName": "JTag",
	}
	rels, err := modelhelper.GetAllRelationships(s)
	if err != nil {
		return fmt.Errorf("tags cannot be fetched for message %s: %s", oldId, err)
	}
	// store tag id/title pairs
	tags := make(map[string]string)
	for _, r := range rels {
		t, err := modelhelper.GetTagById(r.TargetId.Hex())
		if err != nil {
			mwc.log.Error("Tag cannot be fetched for message %s: %s", oldId, err)
			continue
		}

		cml := models.NewChannelMessageList()
		cml.ChannelId = t.SocialApiChannelId
		cml.MessageId = cm.Id
		cml.AddedAt = cm.CreatedAt
		if err := cml.CreateRaw(); err != nil {
			mwc.log.Error("Message tag cannot be created for message %s: %s", oldId, err)
		}

		tags[t.Id.Hex()] = t.Title
	}

	if err := updateBody(cm, tags); err != nil {
		return err
	}

	return nil
}

func updateBody(cm *models.ChannelMessage, tags map[string]string) error {
	newTagExpr := verbalexpressions.New().Find(":").Word().Then("|")
	conditionExpr := verbalexpressions.New().Find("|").Or(newTagExpr)
	tagRegex := verbalexpressions.New().
		BeginCapture().
		Find("|#:JTag:").
		Word().
		And(conditionExpr).
		EndCapture().
		Regex()

	res := tagRegex.FindAllStringSubmatch(cm.Body, -1)
	// no tags found
	if len(res) == 0 {
		return nil
	}

	temp := cm.Body
	for _, element := range res {
		tag := element[0][1 : len(element[1])-1]
		tagId := strings.Split(tag, ":")[2]
		if title, ok := tags[tagId]; ok {
			temp = verbalexpressions.New().Find(element[0]).Replace(temp, fmt.Sprintf("#%s", title))
			continue
		}
		// if tag is not found then remove
		temp = verbalexpressions.New().Find(element[0]).Replace(temp, "")
	}

	cm.Body = temp

	return cm.UpdateBodyRaw()
}

func completeTagMigration(tag *mongomodels.Tag, channelId int64) error {
	tag.SocialApiChannelId = channelId

	return modelhelper.UpdateTag(tag)
}
