// Package sender provides an API for mail sending operations
package emailsender

import (
	"koding/db/mongodb/modelhelper"

	"github.com/koding/bongo"
	"github.com/koding/eventexporter"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

var SendEmailEventName = "send"

// Controller holds required instances for processing events
type Controller struct {
	log             logging.Logger
	emailer         eventexporter.Exporter
	forcedRecipient string
}

// New Creates a new controller for mail worker
func New(exporter eventexporter.Exporter, log logging.Logger) *Controller {
	return &Controller{
		emailer: exporter,
		log:     log,
	}
}

// Send gets the mail struct that includes the message
// when we call this function, it sends the given mail to the
// address that will be sent.
func Send(m *Mail) error {
	return bongo.B.PublishEvent(SendEmailEventName, m)
}

// Process creates and sets the message that will be sent,
// and sends the message according to the mail adress
// its a helper method to send message
func (c *Controller) Process(m *Mail) error {
	var to = m.To

	if isForceRecipient(c.forcedRecipient) {
		to = c.forcedRecipient
	}

	user := &eventexporter.User{Email: to}
	if m.Properties == nil {
		m.Properties = NewProperties()
	}

	user.Username = m.Properties.Username

	if user.Username == "" {
		u, err := modelhelper.FetchUserByEmail(to)
		if err != nil {
			user.Username = "unknown user"
		} else {
			user.Username = u.Name
		}
	}

	m.SetOption("subject", m.Subject)

	event := &eventexporter.Event{
		Name:       m.Subject,
		User:       user,
		Body:       &eventexporter.Body{Content: m.HTML},
		Properties: m.Properties.Options,
	}

	return c.emailer.Send(event)
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred while sending email error as %+v ", err.Error())
	delivery.Nack(false, true)

	return false
}

func isForceRecipient(email string) bool {
	return email != ""
}
