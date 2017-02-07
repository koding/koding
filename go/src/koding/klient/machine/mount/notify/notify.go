// Package notify
package notify

import (
	"context"

	"koding/klient/machine/index"
)

type Cache interface {
	Commit(*index.Change) context.Context
}
