package controller

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"socialapi/models"
	"strconv"
)

func (mwc *Controller) migrateAllGroups() {
	mwc.log.Notice("Group migration started")
	s := modelhelper.Selector{
		"migration": modelhelper.Selector{"$exists": false},
	}

	errCount := 0
	successCount := 0

	handleError := func(g *mongomodels.Group, err error) {
		mwc.log.Error("an error occured for group %s: %s", g.Id.Hex(), err)
		errCount++

		s := modelhelper.Selector{"slug": g.Slug}
		o := modelhelper.Selector{"$set": modelhelper.Selector{"migration": MigrationFailed, "error": err.Error()}}
		if err := modelhelper.UpdateGroupPartial(s, o); err != nil {
			mwc.log.Warning("Could not update group document: %s", err)
		}
	}

	migrateGroup := func(group interface{}) error {
		oldGroup := group.(*mongomodels.Group)
		if oldGroup.SocialApiChannelId != "" {
			s := modelhelper.Selector{"slug": oldGroup.Slug}
			o := modelhelper.Selector{"$set": modelhelper.Selector{"migration": MigrationCompleted}}
			modelhelper.UpdateGroupPartial(s, o)
			return nil
		}
		c, err := mwc.createGroupChannel(oldGroup.Slug)
		if err != nil {
			handleError(oldGroup, err)
			return nil
		}

		// if err := mwc.createGroupMembers(&group, c.Id); err != nil {
		// 	handleError(&group, err)
		// 	continue
		//  return nil
		// }

		if err := completeGroupMigration(oldGroup, c.Id); err != nil {
			handleError(oldGroup, err)
			return nil
		}

		successCount++

		return nil
	}

	iterOptions := helpers.NewIterOptions()
	iterOptions.CollectionName = "jGroups"
	iterOptions.F = migrateGroup
	iterOptions.Filter = s
	iterOptions.Result = &mongomodels.Group{}
	iterOptions.Limit = 10000000
	iterOptions.Skip = 0

	helpers.Iter(modelhelper.Mongo, iterOptions)
	helpers.Iter(modelhelper.Mongo, iterOptions)

	mwc.log.Notice("Group migration completed for %d groups with %d errors", successCount, errCount)
}

func (mwc *Controller) createGroupChannel(groupName string) (*models.Channel, error) {
	c := models.NewChannel()
	c.Name = groupName
	c.GroupName = groupName
	c.TypeConstant = models.Channel_TYPE_GROUP

	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Visibility == "visible" {
		c.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
	} else {
		c.PrivacyConstant = models.Channel_PRIVACY_PRIVATE
	}

	// find group owner
	creatorId, err := mwc.fetchGroupOwnerId(group)
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

func (mwc *Controller) createGroupMembers(g *mongomodels.Group, channelId int64) error {
	s := modelhelper.Selector{
		"sourceId":   g.Id,
		"as":         "member",
		"targetName": "JAccount",
	}

	return mwc.createChannelParticipants(s, channelId)
}

func (mwc *Controller) fetchGroupOwnerId(g *mongomodels.Group) (int64, error) {
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

	return mwc.AccountIdByOldId(r.TargetId.Hex())
}

func completeGroupMigration(g *mongomodels.Group, channelId int64) error {
	g.SocialApiChannelId = strconv.FormatInt(channelId, 10)
	g.Migration = MigrationCompleted

	return modelhelper.UpdateGroup(g)
}
