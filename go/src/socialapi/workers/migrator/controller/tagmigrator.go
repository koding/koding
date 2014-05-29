package controller

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
)

func (mwc *MigratorWorkerController) migrateAllTags() error {
	o := modelhelper.Options{
		Sort: "meta.createdAt",
	}
	s := modelhelper.Selector{
		"socialApiChannelId": modelhelper.Selector{"$exists": false},
	}
	errCount := 0

	handleError := func(t *mongomodels.Tag, err error) {
		mwc.log.Error("an error occured for %s: %s", t.Id.Hex(), err)
		errCount++
	}

	for {
		o.Skip = errCount
		tag, err := modelhelper.GetTag(s, o)
		if err != nil {
			if err == modelhelper.ErrNotFound {
				mwc.log.Notice("Tag migration completed with %d errors", errCount)
				return nil
			}
			return fmt.Errorf("tag cannot be fetched: %s", err)
		}
		c, err := createTagChannel(tag)
		if err != nil {
			handleError(tag, err)
			continue
		}

		if err := completeTagMigration(tag, c); err != nil {
			handleError(tag, err)
			continue
		}

	}

	return nil
}

func createTagChannel(t *mongomodels.Tag) (*models.Channel, error) {
	creatorId, err := fetchTagCreatorId(t)
	if err != nil {
		return nil, err
	}

	c := models.NewChannel()
	c.CreatorId = creatorId
	c.Name = t.Slug
	c.GroupName = t.Group // create group if needed
	// = t.Category "user-tag", "system tag" mevzusu ama bug isi hala var mi bilmiyorum
	c.Purpose = "Channel for " + c.Name + " topic"
	c.TypeConstant = models.Channel_TYPE_TOPIC
	c.PrivacyConstant = models.Channel_PRIVACY_PRIVATE
	c.CreatedAt = t.Meta.CreatedAt
	c.UpdatedAt = t.Meta.ModifiedAt
	if err := c.CreateRaw(); err != nil {
		return nil, err
	}

	return c, nil
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
	a := models.NewAccount()
	a.OldId = r.TargetId.Hex()

	if err := a.FetchOrCreate(); err != nil {
		return 0, fmt.Errorf("Tag creator cannot be created: %s", err)
	}

	return a.Id, nil
}

func completeTagMigration(tag *mongomodels.Tag, c *models.Channel) error {
	tag.SocialApiChannelId = c.Id

	return modelhelper.UpdateTag(tag)
}
