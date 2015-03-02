package sender

import (
	"fmt"

	"github.com/streadway/amqp"

	"github.com/koding/logging"
)

// Controller holds required instances for processing events
type Controller struct {
	// logging instance
	log logging.Logger
}

// New Creates a new controller for realtime package
func New(log logging.Logger) *Controller {
	ffc := &Controller{
		log: log,
	}

	return ffc
}

type Mail struct {
	Body string
}

func (m Mail) GetId() int64 {
	return 0
}

func (m Mail) BongoName() string {
	return "api.mail"
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (r *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	r.log.Error("an error occurred deleting realtime event", err)
	delivery.Nack(false, true)
	return false
}

func (f *Controller) Send(m *Mail) error {
	fmt.Println(m)
	return nil
}
