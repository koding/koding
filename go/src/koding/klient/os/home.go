package os

import (
	"errors"
	"os/user"

	"github.com/koding/kite"
)

var userLookup = user.Lookup

type HomeOptions struct {
	Username string
}

func Home(r *kite.Request) (interface{}, error) {
	var opts HomeOptions

	if r.Args != nil {
		if err := r.Args.One().Unmarshal(&opts); err != nil {
			return nil, err
		}
	}

	if opts.Username == "" {
		return nil, errors.New("Username is required.")
	}

	u, err := userLookup(opts.Username)
	if err != nil {
		r.LocalKite.Log.Error("Home lookup failed. err:%s", err)
		return nil, err
	}

	return u.HomeDir, nil
}
