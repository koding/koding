package kloud

import (
	"errors"

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
		return nil, errors.New("eventId is missing.")
	}

	if args.Type == "" {
		return nil, errors.New("event type is missing.")
	}

	ev := k.GetEvent(args.Type + "-" + args.EventId)
	return ev, nil
}
