// Package sender provides an API for mail sending operations
package emailsender

import (
	"bytes"
	"errors"
	"fmt"
	"html/template"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	texttemplate "text/template"

	"github.com/koding/logging"
	"github.com/mailgun/mailgun-go"
	"gopkg.in/mgo.v2/bson"
)

type EmailInvitationUser struct {
	UserID          string
	Link            string
	LinkUnsubscribe string
	Pin             string
}

type MailgunSender struct {
	Conf                   *config.Config
	Mailgun                mailgun.Mailgun
	TemplateSignup         *template.Template
	TemplateTeamInvite     *template.Template
	TemplateSignupText     *texttemplate.Template
	TemplateTeamInviteText *texttemplate.Template
	VmHostname             string
	Log                    logging.Logger
}

func NewMailgunSender(hostname string, log logging.Logger) *MailgunSender {
	var err error
	ms := &MailgunSender{}

	ms.Log = log
	ms.VmHostname = hostname
	ms.Conf = config.MustGet()
	ms.Mailgun = mailgun.NewMailgun(ms.Conf.Mailgun.Domain, ms.Conf.Mailgun.PrivateKey, ms.Conf.Mailgun.PublicKey)

	ms.TemplateSignup, err = template.New("email").Parse(TemplateSignup)
	if err != nil {
		panic(err)
	}

	ms.TemplateTeamInvite, err = template.New("email").Parse(TemplateTeamInvite)
	if err != nil {
		panic(err)
	}

	ms.TemplateSignupText, err = texttemplate.New("email").Parse(TemplateSignupText)
	if err != nil {
		panic(err)
	}

	ms.TemplateTeamInviteText, err = texttemplate.New("email").Parse(TemplateTeamInviteText)
	if err != nil {
		panic(err)
	}

	return ms
}

func (m *MailgunSender) SendMailgunEmail(mail *Mail) error {
	var subject string
	var email string
	var nickname string
	var err error
	var tpl *template.Template
	var tplText *texttemplate.Template
	userObj := EmailInvitationUser{}

	if mail.Properties.Options["subject"] == keyStartRegister {
		userMap := mail.Properties.Options["user"].(map[string]interface{})
		nickname = userMap["user_id"].(string)
		email = userMap["email"].(string)
		subject = subjectStartRegister
		userObj.UserID = nickname
		userObj.Pin = mail.Properties.Options["pin"].(string)
		tpl = m.TemplateSignup
		tplText = m.TemplateSignupText
	} else if mail.Properties.Options["subject"] == keyInvitedCreateTeam {
		email = mail.Properties.Options["invitee"].(string)
		nickname = email
		userObj.UserID = email
		userObj.Link = mail.Properties.Options["link"].(string)
		subject = subjectInvitedCreateTeam
		tpl = m.TemplateTeamInvite
		tplText = m.TemplateTeamInviteText
	} else {
		return errors.New("Wrong subject in mailgun.go")
	}

	user, err := modelhelper.FetchUserByEmail(email)
	if err != nil {
		user = &models.User{
			Name:     nickname,
			ObjectId: bson.NewObjectId(),
			Email:    email,
		}
		err = modelhelper.CreateUser(user)
		if err != nil {
			return err
		}
	} else if user.EmailFrequency != nil && !user.EmailFrequency.Global {
	    return errors.New("User is unsubscribed from all emails")
	}

	userObj.LinkUnsubscribe = fmt.Sprintf("%s/Unsubscribe/%s/%s", m.VmHostname, user.ObjectId.Hex(), email)

	buf := new(bytes.Buffer)
	err = tpl.Execute(buf, userObj)
	if err != nil {
		m.Log.Error("Sending email template execute err: %s", err)
		return err
	}

	bufText := new(bytes.Buffer)
	err = tplText.Execute(bufText, userObj)

	if err != nil {
		m.Log.Error("Sending email template execute err: %s", err)
		return err
	}

	message := mailgun.NewMessage(
		emailFrom,
		subject,
		bufText.String(),
		email)

	message.SetHtml(buf.String())
	_, _, err = m.Mailgun.Send(message)
	if err != nil {
		m.Log.Error("Sending email err: %s", err)
		return err
	}

	return err
}
