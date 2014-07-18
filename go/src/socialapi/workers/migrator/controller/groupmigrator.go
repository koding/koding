package controller

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"socialapi/models"
	"strconv"
)

func (mwc *Controller) migrateAllGroups() error {
	s := modelhelper.Selector{
		"socialApiChannelId": modelhelper.Selector{"$exists": false},
	}

	errCount := 0
	successCount := 0

	handleError := func(g *mongomodels.Group, err error) {
		mwc.log.Error("an error occured for group %s: %s", g.Id.Hex(), err)
		errCount++
	}

	migrateGroup := func(group interface{}) error {
		oldGroup := group.(*mongomodels.Group)
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

	return nil
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

func (mwc *Controller) createGroupMembers(g *mongomodels.Group, channelId int64) error {
	s := modelhelper.Selector{
		"sourceId":   g.Id,
		"as":         "member",
		"targetName": "JAccount",
	}

	return mwc.createChannelParticipants(s, channelId)
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

	id, err := models.AccountIdByOldId(r.TargetId.Hex(), "")
	if err != nil {
		return 0, err
	}

	return id, nil
}

func completeGroupMigration(g *mongomodels.Group, channelId int64) error {
	g.SocialApiChannelId = strconv.FormatInt(channelId, 10)

	return modelhelper.UpdateGroup(g)
}
