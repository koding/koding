package models

import (
	"errors"
	"fmt"

	socialmodels "socialapi/models"
	"socialapi/workers/notification/models"
	"time"
)

type MailerContainer struct {
	Activity        *models.NotificationActivity
	Content         *models.NotificationContent
	AccountId       int64
	Message         string
	Slug            string
	ActivityMessage string
	ObjectType      string
	Group           GroupContent
	CreatedAt       time.Time
}

func NewMailerContainer() *MailerContainer {
	return &MailerContainer{}
}

func (mc *MailerContainer) PrepareContainer() error {
	if err := mc.validateContainer(); err != nil {
		return err
	}

	// if content type not valid return
	contentType, err := mc.Content.GetContentType()
	if err != nil {
		return err
	}

	// if notification target is related with an object (comment/status update)
	if mc.containsObject() {
		// TODO keep target retrieval out of models
		target := socialmodels.NewChannelMessage()
		if err := target.ById(mc.Content.TargetId); err != nil {
			return fmt.Errorf("target message not found")
		}

		mc.prepareGroup(target)
		mc.prepareSlug(target)
		mc.prepareObjectType(target)
		mc.Message = mc.fetchContentBody(target)
		contentType.SetActorId(target.AccountId)
		contentType.SetListerId(mc.AccountId)
	}

	mc.ActivityMessage = contentType.GetActivity()

	return nil
}

func (mc *MailerContainer) validateContainer() error {
	if mc.AccountId == 0 {
		return errors.New("account id is not set")
	}
	if mc.Activity == nil {
		return errors.New("activity is not set")
	}
	if mc.Content == nil {
		return errors.New("content is not set")
	}

	return nil
}

func (mc *MailerContainer) containsObject() bool {
	return mc.Content.TypeConstant == models.NotificationContent_TYPE_LIKE ||
		mc.Content.TypeConstant == models.NotificationContent_TYPE_MENTION ||
		mc.Content.TypeConstant == models.NotificationContent_TYPE_COMMENT
}

func (mc *MailerContainer) prepareGroup(cm *socialmodels.ChannelMessage) {
	c := socialmodels.NewChannel()
	if err := c.ById(cm.InitialChannelId); err != nil {
		return
	}
	// TODO fix these Slug and Name
	mc.Group = GroupContent{
		Slug: c.GroupName,
		Name: c.GroupName,
	}
}

func (mc *MailerContainer) prepareSlug(cm *socialmodels.ChannelMessage) {
	switch cm.TypeConstant {
	case socialmodels.ChannelMessage_TYPE_POST:
		mc.Slug = cm.Slug
	case socialmodels.ChannelMessage_TYPE_REPLY:
		// TODO we need append something like comment id to parent message slug
		mc.Slug = fetchRepliedMessage(cm.Id).Slug
	}
}

func (mc *MailerContainer) prepareObjectType(cm *socialmodels.ChannelMessage) {
	switch cm.TypeConstant {
	case socialmodels.ChannelMessage_TYPE_POST:
		mc.ObjectType = "status update"
	case socialmodels.ChannelMessage_TYPE_REPLY:
		mc.ObjectType = "comment"
	}
}

func (mc *MailerContainer) fetchContentBody(cm *socialmodels.ChannelMessage) string {

	switch mc.Content.TypeConstant {
	case models.NotificationContent_TYPE_LIKE:
		return cm.Body
	case models.NotificationContent_TYPE_MENTION:
		return cm.Body
	case models.NotificationContent_TYPE_COMMENT:
		return fetchLastReplyBody(cm.Id)
	}

	return ""
}

func fetchRepliedMessage(replyId int64) *socialmodels.ChannelMessage {
	mr := socialmodels.NewMessageReply()
	mr.ReplyId = replyId

	parent, err := mr.FetchParent()
	if err != nil {
		parent = socialmodels.NewChannelMessage()
	}

	return parent
}

func fetchLastReplyBody(targetId int64) string {
	mr := socialmodels.NewMessageReply()
	mr.MessageId = targetId
	query := socialmodels.NewQuery()
	query.Limit = 1
	messages, err := mr.List(query)
	if err != nil {
		return ""
	}

	if len(messages) == 0 {
		return ""
	}

	return messages[0].Body
}
