package trollmode

import (
	"encoding/json"
	"socialapi/models"

	"github.com/koding/logging"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
)

type Action func(*TrollModeController, *models.Account) error

type TrollModeController struct {
	routes map[string]Action
	log    logging.Logger
}

func (t *TrollModeController) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occured putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func NewTrollModeController(log logging.Logger) *TrollModeController {
	ffc := &TrollModeController{
		log: log,
	}

	routes := map[string]Action{
		"api.account_marked_as_troll":   (*TrollModeController).MarkedAsTroll,
		"api.account_unmarked_as_troll": (*TrollModeController).UnMarkedAsTroll,
	}

	ffc.routes = routes

	return ffc
}

func (t *TrollModeController) HandleEvent(event string, data []byte) error {
	t.log.Debug("New Event Received %s", event)
	handler, ok := t.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	acc, err := mapMessage(data)
	if err != nil {
		return err
	}

	return handler(t, acc)
}

func (t *TrollModeController) MarkedAsTroll(data *models.Account) error {
	t.log.Critical("marked as troll ehehe %v", data)
	return nil
}

func (t *TrollModeController) UnMarkedAsTroll(data *models.Account) error {
	t.log.Critical("un marked as troll ehehe %v", data)
	return nil
}

func mapMessage(data []byte) (*models.Account, error) {
	cm := models.NewAccount()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}
