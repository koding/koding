package models

import (
	"socialapi/config"
	"socialapi/workers/email/emailmodels"
)

const TIMEFORMAT = "3:04 PM"

type TemplateParser struct {
	UserContact *emailmodels.UserContact
}

func NewTemplateParser() *TemplateParser {
	return &TemplateParser{}
}

func (tp *TemplateParser) RenderInstantTemplate(mc *MailerContainer) (string, error) {
	bc := emailmodels.NewBodyContent()
	mg, err := buildMessageContent(mc)
	if err != nil {
		return "", err
	}

	bc.AddMessageGroup(mg)

	return bc.Render()
}

func (tp *TemplateParser) RenderDailyTemplate(containers []*MailerContainer) (string, error) {
	bc := emailmodels.NewBodyContent()
	for _, mc := range containers {
		mg, err := buildMessageContent(mc)
		if err != nil {
			continue
		}
		bc.AddMessageGroup(mg)
	}

	bc.Title = "Here what's happened on Koding today!"

	return bc.Render()
}

func buildMessageContent(mc *MailerContainer) (*emailmodels.MessageGroupSummary, error) {
	mg := emailmodels.NewMessageGroupSummary()
	title, err := prepareTitle(mc)
	if err != nil {
		return nil, err
	}
	mg.Title = title

	// message
	ms := new(emailmodels.MessageSummary)
	ms.Body = mc.Message
	mg.AddMessage(ms, mc.Activity.CreatedAt)

	actor, err := emailmodels.FetchUserContact(mc.Activity.ActorId)
	if err != nil {
		return nil, err
	}

	mg.Nickname = actor.Username
	mg.AccountId = actor.AccountId
	mg.Hash = actor.Hash

	return mg, nil
}

func prepareTitle(mc *MailerContainer) (string, error) {
	ac := new(ActionContent)
	ac.Action = mc.ActivityMessage
	ac.Hostname = config.MustGet().Hostname
	ac.ObjectType = mc.ObjectType
	ac.Slug = mc.Slug

	return ac.Render()
}
