package models

import (
	"time"

	"github.com/koding/bongo"
)

// NewPresenceDaily create new PresenceDaily item
func NewPresenceDaily() *PresenceDaily {
	return &PresenceDaily{
		CreatedAt: time.Now().UTC(),
	}
}

// GetId returns the id
func (a PresenceDaily) GetId() int64 {
	return a.Id
}

// BongoName returns the unique name for the bongo operations
func (a PresenceDaily) BongoName() string {
	return "presence.daily"
}

// One fetches the item from db
func (a *PresenceDaily) One(q *bongo.Query) error {
	return bongo.B.One(a, a, q)
}

// Delete deletes the item from db
func (a *PresenceDaily) Delete() error {
	return bongo.B.Delete(a)
}

// Create inserts into db
func (a *PresenceDaily) Create() error {
	return bongo.B.Create(a)
}

// Some fetches items from db
func (a *PresenceDaily) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(a, data, q)
}
