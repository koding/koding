package kloud

import "github.com/koding/kite"

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

	ev := k.GetEvent(args.Type + "-" + args.EventId)
	return ev, nil
}
