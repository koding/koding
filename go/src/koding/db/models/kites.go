package models

import (
	"koding/newkite/protocol"
	"time"
)

// Kite is a structure representing a Kite in database.
type Kite struct {
	protocol.Kite `bson:",inline"`
	UpdatedAt     time.Time `bson:"updatedAt"`
	KodingKey     string    `bson:"kodingKey" json:"kodingKey"`
}

func (k *Kite) Addr() string { return k.PublicIP + ":" + k.Port }
