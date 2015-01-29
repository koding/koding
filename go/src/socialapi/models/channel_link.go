package models

import "time"

// ChannelLink holds the link between two channels
type ChannelLink struct {
	// Id holds the unique id of the link between channels
	Id int64 `json:"id,string"`

	// RootId is the id of the root channel
	RootId int64 `json:"rootId,string"       sql:"NOT NULL"`

	// LeafId is the id of the leaf channel
	LeafId int64 `json:"leafId,string"       sql:"NOT NULL"`

	// CreatedAt holds the creation time of the channel_link
	CreatedAt time.Time `json:"createdAt"    sql:"NOT NULL"`
}
