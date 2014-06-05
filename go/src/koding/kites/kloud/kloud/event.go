package kloud

import (
	"koding/kites/kloud/eventer"

	"github.com/koding/kite"
)

type EventArgs struct {
	Type    string
	EventId string
}

func (k *Kloud) event(r *kite.Request) (interface{}, error) {
	args := &EventArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.EventId == "" {
		return nil, NewError(ErrEventIdMissing)
	}

	if args.Type == "" {
		return nil, NewError(ErrEventTypeMissing)
	}

	ev, err := k.GetEvent(args.Type + "-" + args.EventId)
	if err != nil {
		return nil, err
	}

	k.Log.Debug("[event]: returning: %s for the args: %v to user: %s",
		ev.String(), args, r.Username)

	return ev, nil
}

func (k *Kloud) NewEventer(id string) eventer.Eventer {
	k.Log.Debug("creating a new eventer for id: %s", id)
	ev, ok := k.Eventers[id]
	if ok {
		// for now we delete old events, but in the future we might store them
		// in the db for history/logging.
		k.Log.Debug("cleaning up previous events of id: %s", id)
		delete(k.Eventers, id)
	}

	ev = eventer.New(id)
	k.Eventers[id] = ev
	return ev
}

func (k *Kloud) GetEvent(eventId string) (*eventer.Event, error) {
	ev, ok := k.Eventers[eventId]
	if !ok {
		return nil, NewError(ErrEventNotFound)
	}

	return ev.Show(), nil
}
