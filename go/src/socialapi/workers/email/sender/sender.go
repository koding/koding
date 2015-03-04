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
	log      logging.Logger
	sendgrid *sendgrid.SGClient
}

// New Creates a new controller for mail worker
func New(log logging.Logger, s *sendgrid.SGClient) *Controller {
	return &Controller{
		log:      log,
		sendgrid: s,
	}
}

func Send(m *Mail) error {
	return bongo.B.PublishEvent("send", m)
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred %+v", err.Error())
	delivery.Nack(false, true)

	return false
}

func (c *Controller) Send(m *Mail) error {
	fmt.Println(m)

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
	if err := message.SetReplyTo(m.ReplyTo); err != nil {
		return err
	}

	if err := c.sendgrid.Send(message); err != nil {
		return fmt.Errorf("an error occurred while sending email error as %+v ", err.Error())
	}

	return nil
}
