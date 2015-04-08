package models

import (
	"time"

	"github.com/koding/bongo"
)

const (
	// ChannelLinkBongoName holds the bongo name for channel link struct
	ChannelLinkBongoName = "api.channel_link"
)

func (c *ChannelLink) validateBeforeOps() error {
	if c.RootId == 0 {
		return ErrRootIsNotSet
	}

	if c.LeafId == 0 {
		return ErrLeafIsNotSet
	}

	r := NewChannel()
	if err := r.ById(c.RootId); err != nil {
		return err
	}

	l := NewChannel()
	if err := l.ById(c.LeafId); err != nil {
		return err
	}

	if r.GroupName != l.GroupName {
		return ErrGroupsAreNotSame
	}

	// leaf channel should not be a root channel of another channel
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"root_id": c.LeafId,
		},
	}

	count, err := NewChannelLink().CountWithQuery(query)
	if err != nil && err != bongo.RecordNotFound {
		return err
	}

	if count > 0 {
		return ErrLeafIsRootToo
	}

	return nil
}

// BeforeCreate runs before persisting struct to db
func (c *ChannelLink) BeforeCreate() error {
	if err := c.validateBeforeOps(); err != nil {
		return err
	}

	c.CreatedAt = time.Now().UTC()
	return nil
}

// BeforeUpdate runs before updating struct
func (c *ChannelLink) BeforeUpdate() error {
	return c.validateBeforeOps()
}

// AfterCreate runs after persisting struct to db
func (c *ChannelLink) AfterCreate() {
	bongo.B.AfterCreate(c)
}

// AfterUpdate runs after updating struct
func (c *ChannelLink) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

// AfterDelete runs after deleting struct
func (c *ChannelLink) AfterDelete() {
	bongo.B.AfterDelete(c)
}

// GetId returns the Id of the struct
func (c ChannelLink) GetId() int64 {
	return c.Id
}

// BongoName returns the name for bongo operations
func (c ChannelLink) BongoName() string {
	return ChannelLinkBongoName
}

// TableName overrides the gorm table name
func (c ChannelLink) TableName() string {
	return c.BongoName()
}

// NewChannelLink creates a new channel link with default values
func NewChannelLink() *ChannelLink {
	return &ChannelLink{}
}

// Update updates the channel link
func (c *ChannelLink) Update() error {
	return bongo.B.Update(c)
}

// ById fetches the data from db by the record primary key
func (c *ChannelLink) ById(id int64) error {
	return bongo.B.ById(c, id)
}

// UnscopedById fetches the data from db by the record primary key without any
// scopes
func (c *ChannelLink) UnscopedById(id int64) error {
	return bongo.B.UnscopedById(c, id)
}

// One fetches a record from db with given query parameters, if not found,
// returns an error
func (c *ChannelLink) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

// Some fetches some records from db with given query parameters, if not found
// any record, doesnt return any error
func (c *ChannelLink) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}

// UpdateMulti updates multiple channel links at one
func (c *ChannelLink) UpdateMulti(rest ...map[string]interface{}) error {
	return bongo.B.UpdateMulti(c, rest...)
}

// CountWithQuery returns a count for the given query
func (c *ChannelLink) CountWithQuery(q *bongo.Query) (int, error) {
	return bongo.B.CountWithQuery(c, q)
}
