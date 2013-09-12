package models

import (
	"koding/newkite/protocol"
	"net/rpc"
	"time"
)

type Kite struct {
	protocol.Base `bson:",inline"`
	UpdatedAt     time.Time   `bson:"updatedAt"`
	Client        *rpc.Client `json:"-"`
}
