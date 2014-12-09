package models

import (
	"socialapi/config"
	"socialapi/workers/email/emailmodels"
)

type TemplateParser struct {
	UserContact *emailmodels.UserContact
}

func NewTemplateParser() *TemplateParser {
	return &TemplateParser{}
}

func (tp *TemplateParser) RenderInstantTemplate(mc *MailerContainer) (string, error) {
	uc, err := emailmodels.FetchUserContactWithToken(mc.AccountId)
	if err != nil {
		return "", err
	}
	tp.UserContact = uc

	cs, err := tp.buildChannelSummary(mc)
	if err != nil {
		return "", err
	}
	es := emailmodels.NewEmailSummary(cs)

	return es.Render()
}

func (tp *TemplateParser) buildChannelSummary(mc *MailerContainer) (*emailmodels.ChannelSummary, error) {
	actor, err := emailmodels.FetchUserContact(mc.Activity.ActorId)
	if err != nil {
		return nil, err
	}

	cs := new(emailmodels.ChannelSummary)

	ms := emailmodels.NewMessageSummary("", tp.UserContact.LastLoginTimezoneOffset, mc.Message, mc.CreatedAt)

	summary, err := ms.Render()
	if err != nil {
		return nil, err
	}

	// render title/link
	title, err := prepareTitle(mc, actor)
	if err != nil {
		return nil, err
	}

	// render image
	ci := new(emailmodels.ChannelImage)
	ci.Hash = actor.Hash

	image, err := ci.Render()
	if err != nil {
		return nil, err
	}

	cs.Image = image
	cs.Link = title
	cs.Summary = summary

	return cs, nil
}

func (tp *TemplateParser) RenderDailyTemplate(containers []*MailerContainer) (string, error) {
	channelSummaries := make([]*emailmodels.ChannelSummary, 0)
	for _, mc := range containers {
		cs, err := tp.buildChannelSummary(mc)
		if err != nil {
			return "", err
		}
		channelSummaries = append(channelSummaries, cs)
	}

	es := emailmodels.NewEmailSummary(channelSummaries...)

	return es.Render()
}

func prepareTitle(mc *MailerContainer, actor *emailmodels.UserContact) (string, error) {
	ac := new(ActionContent)
	ac.Action = mc.ActivityMessage
	ac.Hostname = config.MustGet().Hostname
	ac.ObjectType = mc.ObjectType
	ac.Slug = mc.Slug
	ac.Nickname = actor.Username

	return ac.Render()
}
