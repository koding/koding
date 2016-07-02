package os

import (
	"os/user"

	"github.com/koding/kite"
)

var currentLookup = user.Current

// CurrentUsername gets the current user that Klient is running as,
func CurrentUsername(r *kite.Request) (interface{}, error) {
	u, err := currentLookup()
	if err != nil {
		r.LocalKite.Log.Error("Current user lookup failed. err:%s", err)
		return nil, err
	}

	return u.Username, nil
}
