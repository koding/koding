// Package notify
package notify

import (
	"context"

	"koding/klient/machine/index"
)

type Cache interface {
	Commit(context.Context, *index.Change) context.Context
}
