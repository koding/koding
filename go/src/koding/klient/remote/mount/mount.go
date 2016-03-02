package mount

import (
	"koding/klient/kiteerrortypes"
	"koding/klient/util"
)

var (
	// Returned by various methods if the requested mount cannot be found.
	ErrMountNotFound error = util.KiteErrorf(
		kiteerrortypes.MountNotFound, "Mount not found",
	)
)
