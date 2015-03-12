// Package models provides the basic data structures for the collaboration worker
package models

import "time"

// Ping holds the ping data that comes from a collaboration session
type Ping struct {
	// FileId holds the collaboration file id
	FileId string `json:"fileId"`

	// ChannelId holds channel id that is used in the collaboration
	ChannelId int64 `json:"channelId,string"`

	// AccountId holds the host's id the only one that can send this request
	AccountId int64 `json:"accountId,string"`

	// CreatedAt holds the ping time
	CreatedAt time.Time `json:"createdAt"`
}

// NewPing creates an empty ping
func NewPing() *Ping {
	return &Ping{}
}

// GetId returns the id of the ping, it is here just to satisfy Bongo.Modellable
// interface
func (a Ping) GetId() int64 {
	return 0
}

// BongoName returns the unique name for the bongo operations
func (a Ping) BongoName() string {
	return "collaboration.ping"
}
