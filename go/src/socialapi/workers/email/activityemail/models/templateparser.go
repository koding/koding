package models

import (
	"socialapi/config"
	"socialapi/workers/email/emailmodels"
	"time"
)

const (
	DATEFORMAT = "Jan 02"
	TIMEFORMAT = "3:04 PM"
)

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

	return bc.Render(), nil
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

	bc.Title = "Here what's happened in Koding today!"

	return bc.Render(), nil
}

func buildMessageContent(mc *MailerContainer) (*emailmodels.MessageGroupSummary, error) {
	mg := emailmodels.NewMessageGroupSummary()
	mg.Title = prepareTitle(mc)

	// message
	ms := new(emailmodels.MessageSummary)
	ms.Body = mc.Message
	ms.Time = prepareTime(mc)
	mg.AddMessage(ms)

	actor, err := emailmodels.FetchUserContact(mc.Activity.ActorId)
	if err != nil {
		return nil, err
	}

	mg.Nickname = actor.Username
	mg.AccountId = actor.AccountId
	mg.Hash = actor.Hash

	return mg, nil
}

func prepareTitle(mc *MailerContainer) string {
	ac := new(ActionContent)
	ac.Action = mc.ActivityMessage
	ac.Hostname = config.MustGet().Hostname
	ac.ObjectType = mc.ObjectType
	ac.Slug = mc.Slug

	return ac.Render()
}

func getMonthAndDay(t time.Time) string {
	return t.Format(DATEFORMAT)
}

func prepareDate(mc *MailerContainer) string {
	return mc.Activity.CreatedAt.Format(DATEFORMAT)
}

func prepareTime(mc *MailerContainer) string {
	return mc.Activity.CreatedAt.Format(TIMEFORMAT)
}
