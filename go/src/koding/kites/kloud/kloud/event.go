package kloud

import "github.com/koding/kite"

type EventArgs struct {
	EventId string
}

func (k *Kloud) event(r *kite.Request) (interface{}, error) {
	args := &EventArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	return k.GetEvent(args.EventId), nil
}
