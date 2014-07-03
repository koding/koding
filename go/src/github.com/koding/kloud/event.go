package kloud

import (
	"github.com/koding/kite"
	"github.com/koding/kloud/eventer"
)

type EventArg struct {
	Type    string
	EventId string
}

type EventArgs []EventArg

type EventResponse struct {
	EventId string         `json:"event_id"`
	Event   *eventer.Event `json:"event"`
	Error   *kite.Error    `json:"err"`
}

func (k *Kloud) event(r *kite.Request) (interface{}, error) {
	args := EventArgs{}
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if len(args) == 0 {
		return nil, NewError(ErrEventArgsEmpty)
	}

	k.Log.Debug("[event] received argument: %v", args)

	events := make([]EventResponse, len(args))

	for i, event := range args {
		if event.EventId == "" {
			events[i] = EventResponse{Error: NewError(ErrEventIdMissing)}
			continue
		}

		if event.Type == "" {
			events[i] = EventResponse{
				EventId: event.EventId,
				Error:   NewError(ErrEventTypeMissing),
			}
			continue
		}

		ev, err := k.GetEvent(event.Type + "-" + event.EventId)
		if err != nil {
			events[i] = EventResponse{
				EventId: event.EventId,
				Error:   &kite.Error{Message: err.Error()},
			}
			continue
		}

		events[i] = EventResponse{EventId: event.EventId, Event: ev}
	}

	k.Log.Debug("[event] returning %+v to user: %s", events, r.Username)
	return events, nil
}

func (k *Kloud) NewEventer(id string) eventer.Eventer {
	k.Log.Debug("[event] creating a new eventer for id: %s", id)
	ev, ok := k.Eventers[id]
	if ok {
		// for now we delete old events, but in the future we might store them
		// in the db for history/logging.
		k.Log.Debug("[event] cleaning up previous events of id: %s", id)
		delete(k.Eventers, id)
	}

	ev = eventer.New(id)
	k.Eventers[id] = ev
	return ev
}

func (k *Kloud) GetEvent(eventId string) (*eventer.Event, error) {
	k.Log.Debug("[event] searching eventer for id: %s", eventId)
	ev, ok := k.Eventers[eventId]
	if !ok {
		k.Log.Debug("[event] couldn't find eventer for id: %s", eventId)
		return nil, NewError(ErrEventNotFound)
	}

	return ev.Show(), nil
}
