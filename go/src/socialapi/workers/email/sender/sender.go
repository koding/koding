package sender

import (
	"fmt"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/sendgrid/sendgrid-go"
	"github.com/streadway/amqp"
)

// Controller holds required instances for processing events
type Controller struct {
	log    logging.Logger
	client Emailer
}

type Emailer interface {
	Send(*sendgrid.SGMail) error
}

// New Creates a new controller for mail worker
func New(log logging.Logger, c Emailer) *Controller {
	return &Controller{
		log:    log,
		client: c,
	}
}

// Send gets the mail struct that includes the message
// when we call this function, it sends the given mail to the
// address that will be sent.
func Send(m *Mail) error {
	return bongo.B.PublishEvent("send", m)
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred %+v", err.Error())
	delivery.Nack(false, true)

	return false
}

// Send creates and sets the message that will be sent,
// and sends the message according to the mail adress
func (c *Controller) Send(m *Mail) error {
	message := sendgrid.NewMail()

	if err := message.AddTo(m.To); err != nil {
		return err
	}

	if err := message.SetFrom("mail@koding.com"); err != nil {
		return err
	}

	if m.From != "" {
		message.SetFrom(m.From)
	}

	message.SetText(m.Text)
	message.SetHTML(m.HTML)
	message.SetSubject(m.Subject)
	message.SetFromName(m.FromName)
	if m.ReplyTo != "" {
		if err := message.SetReplyTo(m.ReplyTo); err != nil {
			return err
		}
	}

	if err := c.client.Send(message); err != nil {
		return fmt.Errorf("an error occurred while sending email error as %+v ", err.Error())
	}

	return nil
}
