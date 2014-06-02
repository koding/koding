package kloud

import (
	"errors"

	"github.com/koding/kite"
)

type EventArgs struct {
	EventId string
}

func (k *Kloud) event(r *kite.Request) (interface{}, error) {
	args := &EventArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.EventId == "" {
		return nil, errors.New("eventId is empty.")

	}

	ev := k.GetEvent(args.EventId)
	return ev, nil
}
