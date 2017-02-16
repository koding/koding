// Package emailsender provides an API for mail sending operations
package emailsender

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"text/template"

	"github.com/koding/bongo"
	"github.com/koding/eventexporter"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

var SendEmailEventName = "send"

const (
	keyInvitedCreateTeam     = "was invited to create a team"
	subjectInvitedCreateTeam = "You're invited to try Koding for Teams!"
	emailFrom                = "Devrim <dy@koding.com>"
)

// Controller holds required instances for processing events
type Controller struct {
	log                     logging.Logger
	emailer                 eventexporter.Exporter
	forcedRecipientUsername string
	forcedRecipientEmail    string
	env                     string
	host                    string
	mailgun                 *MailgunSender
}

// New Creates a new controller for mail worker
// func New(exporter eventexporter.Exporter, log logging.Logger, conf runner.Config) *Controller {
func New(exporter eventexporter.Exporter, log logging.Logger, conf *config.Config) *Controller {
	vmHostname := conf.Protocol + "//" + conf.Hostname
	return &Controller{
		emailer:                 exporter,
		log:                     log,
		env:                     conf.Environment,
		host:                    conf.Hostname,
		forcedRecipientEmail:    conf.Email.ForcedRecipientEmail,
		forcedRecipientUsername: conf.Email.ForcedRecipientUsername,
		mailgun:                 NewMailgunSender(vmHostname, log, conf),
	}
}

// Send gets the mail struct that includes the message
// when we call this function, it sends the given mail to the
// address that will be sent.
func Send(m *Mail) error {
	return bongo.B.PublishEvent(SendEmailEventName, m)
}

// Process creates and sets the message that will be sent,
// and sends the message according to the mail address
// its a helper method to send message
func (c *Controller) Process(m *Mail) error {
	if m.Properties == nil {
		m.Properties = NewProperties()
	}

	user := c.getUserInfo(m)

	m.SetOption("subject", m.Subject)

	// set default properties
	m.SetOption("env", c.env)
	m.SetOption("host", c.host)

	if m.Properties.Options["subject"] == keyInvitedCreateTeam {
		return c.mailgun.SendMailgunEmail(m)
	}

	event := &eventexporter.Event{
		Name: m.Subject,
		User: user,
		Body: &eventexporter.Body{
			Content: template.HTMLEscapeString(m.HTML),
		},
		Properties: m.Properties.Options,
	}
	return c.emailer.Send(event)
}

func (c *Controller) getUserInfo(m *Mail) *eventexporter.User {
	if m.To == "" {
		u, err := modelhelper.GetUser(m.Properties.Username)
		if err == nil {
			m.To = u.Email
		}
	}

	user := &eventexporter.User{Email: m.To}

	if c.forcedRecipientEmail != "" {
		user.Email = c.forcedRecipientEmail
	}

	user.Username = m.Properties.Username
	if c.forcedRecipientUsername != "" {
		user.Username = c.forcedRecipientUsername
	}

	return user
}

// Close closes the emailer
func (c *Controller) Close() {
	if err := c.emailer.Close(); err != nil {
		c.log.Error("Could not close emailer successfully: %s", err)
	}
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		c.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)

		return true
	}

	c.log.Error("an error occurred while sending email error as %+v ", err.Error())
	delivery.Nack(false, true)

	return false
}
