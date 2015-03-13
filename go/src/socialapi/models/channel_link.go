package models

import (
	"socialapi/request"
	"strings"
	"time"

	"github.com/koding/bongo"
)

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

	// options for operations

	// DeleteMessages remove the messages of a channel
	DeleteMessages bool `json:"deleteMessages,omitempty" sql:"-"`
}

func (c *ChannelLink) validate() error {
	if c.LeafId == 0 {
		return ErrLeafIsNotSet
	}

	if c.RootId == 0 {
		return ErrRootIsNotSet
	}

	return nil
}

func (c *ChannelLink) List(q *request.Query) ([]Channel, error) {
	if c.RootId == 0 {
		return nil, ErrRootIsNotSet
	}

	var leafIds []int64

	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"root_id": c.RootId,
		},
		Pluck: "leaf_id",
	}

	err := c.Some(&leafIds, bq)
	if err != nil {
		return nil, err
	}

	return NewChannel().FetchByIds(leafIds)
}

func (c *ChannelLink) UnLink() error {
	if err := c.validate(); err != nil {
		return err
	}

	// first update the leaf node with it's previous channel type constant
	ch := NewChannel()
	if err := ch.ById(c.LeafId); err != nil {
		if err == bongo.RecordNotFound {
			return ErrChannelNotFound
		}

		return err
	}

	ch.TypeConstant = strings.TrimPrefix(
		ch.TypeConstant,
		ChannelLinkedPrefix,
	)

	if err := ch.Update(); err != nil {
		return err
	}

	// then delete the link between two channels
	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"root_id": c.RootId,
			"leaf_id": c.LeafId,
		},
	}

	if err := c.One(bq); err != nil {
		return err
	}

	return ch.Delete()
}

func (c *ChannelLink) Blacklist() error {
	if c.RootId == 0 {
		return ErrRootIsNotSet
	}

	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"root_id": c.RootId,
		},
	}

	// if channel has some leaves, do not continue
	if c.One(bq) != bongo.RecordNotFound {
		return ErrChannelHasLeaves
	}

	// first update the leaf node with it's previous channel type constant
	ch := NewChannel()
	if err := ch.ById(c.RootId); err != nil {
		if err == bongo.RecordNotFound {
			return ErrChannelNotFound
		}

		return err
	}

	// mark channel as linked
	ch.TypeConstant = ChannelLinkedPrefix + ch.TypeConstant

	if err := ch.Update(); err != nil {
		return err
	}

	return nil
}
