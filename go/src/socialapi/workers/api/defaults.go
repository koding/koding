package main

import (
	"fmt"
	kodingmodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"strconv"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/bongo"
	"github.com/koding/logging"
)

func setDefaults(log logging.Logger) {
	group, err := modelhelper.GetGroup(models.Channel_KODING_NAME)
	if err != nil {
		log.Error("err while fetching koding group: %s", err.Error())
		return
	}

	log.Debug("mongo group found")

	setPublicChannel(log, group)
	setChangeLogChannel(log, group)
	log.Info("socialApi defaults are created")
}

func setPublicChannel(log logging.Logger, group *kodingmodels.Group) {
	c := models.NewChannel()
	selector := map[string]interface{}{
		"type_constant": models.Channel_TYPE_GROUP,
		"group_name":    models.Channel_KODING_NAME,
	}

	err := c.One(bongo.NewQS(selector))
	if err != nil && err != bongo.RecordNotFound {
		log.Error("err while fetching koding channel:", err.Error())
		return
	}

	if err == bongo.RecordNotFound {
		log.Debug("postgres group couldn't found, creating it")

		acc, err := createChannelOwner(group)
		if err != nil {
			log.Error(err.Error())
			return
		}

		c.Name = "public"
		c.CreatorId = acc.Id
		c.GroupName = models.Channel_KODING_NAME
		c.TypeConstant = models.Channel_TYPE_GROUP
		c.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
		if err := c.Create(); err != nil {
			log.Error("err while creating the koding channel: %s", err.Error())
			return
		}
	}

	socialApiId := strconv.FormatInt(c.Id, 10)
	if group.SocialApiChannelId == socialApiId {
		log.Debug("mongo and postgres socialApiChannelId ids are same")
		return
	}

	log.Debug("mongo and postgres socialApiChannelId ids are different, fixing it")
	if err := updateGroupPartially(group.Id, "socialApiChannelId", socialApiId); err != nil {
		log.Error("err while udpating socialApiChannelId: %s", err.Error())
		return
	}
}

func setChangeLogChannel(log logging.Logger, group *kodingmodels.Group) {

	c := models.NewChannel()
	selector := map[string]interface{}{
		"type_constant": models.Channel_TYPE_ANNOUNCEMENT,
		"group_name":    models.Channel_KODING_NAME,
	}

	// if err is nil
	// it means we already have that channel
	err := c.One(bongo.NewQS(selector))
	if err != nil && err != bongo.RecordNotFound {
		log.Error("err while fetching changelog channel:", err.Error())
		return
	}

	if err == bongo.RecordNotFound {
		log.Error("postgres changelog couldn't found, creating it")

		acc, err := createChannelOwner(group)
		if err != nil {
			log.Error(err.Error())
			return
		}

		c.Name = "changelog"
		c.CreatorId = acc.Id
		c.GroupName = models.Channel_KODING_NAME
		c.TypeConstant = models.Channel_TYPE_ANNOUNCEMENT
		c.PrivacyConstant = models.Channel_PRIVACY_PRIVATE
		if err := c.Create(); err != nil {
			log.Error("err while creating the koding channel:", err.Error())
			return
		}
	}
}

func createChannelOwner(group *kodingmodels.Group) (*models.Account, error) {
	owner, err := modelhelper.GetGroupOwner(group)
	if err != nil {
		return nil, fmt.Errorf("err while fetching koding owner: %s", err.Error())
	}

	acc := models.NewAccount()
	acc.OldId = owner.Id.Hex()
	acc.Nick = owner.Profile.Nickname
	if err := acc.FetchOrCreate(); err != nil {
		return nil, fmt.Errorf("err while fetching owner from postgres: %s", err.Error())
	}

	return acc, nil
}

func updateGroupPartially(groupId bson.ObjectId, property string, value string) error {
	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": groupId},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				property: value,
			},
		},
	)
}
