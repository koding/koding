package stack

import (
	"koding/kites/kloud/eventer"

	"github.com/koding/kite"
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

func (k *Kloud) Event(r *kite.Request) (interface{}, error) {
	args := EventArgs{}
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if len(args) == 0 {
		return nil, NewError(ErrEventArgsEmpty)
	}

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

	return events, nil
}

func (k *Kloud) NewEventer(id string) eventer.Eventer {
	k.Log.Debug("[event] creating a new eventer for id: %s", id)

	k.mu.Lock()
	defer k.mu.Unlock()

	_, ok := k.Eventers[id]
	if ok {
		// for now we delete old events, but in the future we might store them
		// in the db for history/logging.
		k.Log.Debug("[event] cleaning up previous events of id: %s", id)
		delete(k.Eventers, id)
	}

	ev := eventer.New(id)
	k.Eventers[id] = ev
	return ev
}

func (k *Kloud) DelEventer(id string) {
	k.Log.Debug("[event] cleaning up previous events of id: %s", id)

	k.mu.Lock()
	delete(k.Eventers, id)
	k.mu.Unlock()
}

func (k *Kloud) GetEvent(eventId string) (*eventer.Event, error) {
	// k.Log.Debug("[event] searching eventer for id: %s", eventId)
	k.mu.RLock()
	ev, ok := k.Eventers[eventId]
	k.mu.RUnlock()
	if !ok {
		k.Log.Debug("[event] couldn't find eventer for id: %s", eventId)
		return nil, NewError(ErrEventNotFound)
	}

	return ev.Show(), nil
}
