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

	// IsFinished holds the linking process
	// we link leaf channel to the root channel
	// and marks channel_link as true
	// if isFinished is false, it means
	// linking the channels process is not done yet.
	IsFinished bool `json:"isFinished"       sql:"NOT NULL"`

	// options for operations

	// DeleteMessages remove the messages of a channel
	DeleteMessages bool `json:"deleteMessages,omitempty" sql:"-"`
}

// List gets the all leaves of a given channel
func (c *ChannelLink) List(q *request.Query) ([]Channel, error) {
	if c.RootId == 0 {
		return nil, ErrRootIsNotSet
	}

	var leafIds []int64

	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"root_id": c.RootId,
		},
		Pluck:      "leaf_id",
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	err := c.Some(&leafIds, bq)
	if err != nil {
		return nil, err
	}

	return NewChannel().FetchByIds(leafIds)
}

// FetchRoot fetches the root of a channel if linked
func (c *ChannelLink) FetchRoot() (*Channel, error) {
	if c.LeafId == 0 {
		return nil, ErrLeafIsNotSet
	}

	var rootIds []int64

	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"leaf_id": c.LeafId,
		},
		Pluck: "root_id",
	}

	if err := c.Some(&rootIds, bq); err != nil {
		return nil, err
	}

	if len(rootIds) == 0 {
		return nil, bongo.RecordNotFound
	}

	channel := NewChannel()
	if err := channel.ById(rootIds[0]); err != nil {
		return nil, err
	}

	return channel, nil
}

// ChannelLinksWithRoot fetches the links with root of channel
func (c *ChannelLink) ChannelLinksWithRoot() ([]ChannelLink, error) {
	var cLinks []ChannelLink

	query := bongo.B.DB.Table(c.BongoName())
	query = query.Where("root_id = ? or leaf_id = ?", c.RootId, c.RootId)

	if err := query.Find(&cLinks).Error; err != nil && err != bongo.RecordNotFound {
		return nil, err
	}

	if cLinks == nil {
		return nil, nil
	}

	if len(cLinks) == 0 {
		return nil, nil
	}

	return cLinks, nil
}

// RemoveLinksWithRoot removes the links of the given root channel
func (c *ChannelLink) RemoveLinksWithRoot() error {
	links, err := c.ChannelLinksWithRoot()
	if err != nil && err != bongo.RecordNotFound {
		return err
	}

	var errs error

	for _, link := range links {
		// ignore all not found errors while deleting links
		err := link.Delete()
		if err != nil && err != ErrChannelNotFound {
			errs = err
		}
	}

	if errs != nil {
		return errs
	}

	return nil
}

// Create creates a link between two channels
func (c *ChannelLink) Create() error {
	return c.create()
}

// Delete removes the link between two channels, most probably it wont touch to
// the messages
func (c *ChannelLink) Delete() error {
	if err := c.validate(); err != nil {
		return err
	}

	// first update the leaf node with it's previous channel type constant
	leaf := NewChannel()
	if err := leaf.ById(c.LeafId); err != nil {
		if err == bongo.RecordNotFound {
			return ErrChannelNotFound
		}

		return err
	}

	leaf.TypeConstant = strings.TrimPrefix(
		string(leaf.TypeConstant),
		ChannelLinkedPrefix,
	)

	if err := leaf.Update(); err != nil {
		return err
	}

	toBeDeletedCL := NewChannelLink()
	// then delete the link between two channels
	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"root_id": c.RootId,
			"leaf_id": c.LeafId,
		},
	}

	if err := toBeDeletedCL.One(bq); err != nil {
		return err
	}

	return bongo.B.Delete(toBeDeletedCL)
}

// Blacklist deletes the messages and links the leaf channel to the root while
// removing the participants
func (c *ChannelLink) Blacklist() error {
	c.DeleteMessages = true
	return c.Create()
}

func (c *ChannelLink) create() error {
	if err := c.validate(); err != nil {
		return err
	}

	// it controls the channel linking process, if not finished
	// then dont try to link another channel and return error
	isInProgress, err := c.IsInProgress(c.RootId)
	if err != nil {
		return err
	}
	if isInProgress {
		return ErrLinkingProcessNotDone
	}

	// then delete the link between two channels
	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"root_id": c.RootId,
			"leaf_id": c.LeafId,
		},
	}

	// if there is no error, it means we already have it
	if err := c.One(bq); err == nil {
		c.AfterCreate() // just mimic as if created
		return nil
	}

	// first update the leaf
	leaf := NewChannel()
	if err := leaf.ById(c.LeafId); err != nil {
		if err == bongo.RecordNotFound {
			return ErrChannelNotFound
		}

		return err
	}

	// mark channel as linked
	leaf.TypeConstant = ChannelLinkedPrefix + leaf.TypeConstant

	if err := leaf.Update(); err != nil {
		return err
	}

	return bongo.B.Create(c)
}

// IsInProgress checks the db if linking process is completely done or not
// if true -> linking process is not done
// if false -> linking process is completely done
// We will searh root channel in db as leaf channel,
// Aim of this search, protect linking conflict of root-leaf channels
func (c *ChannelLink) IsInProgress(rootID int64) (bool, error) {
	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"leaf_id":     rootID,
			"is_finished": false,
		},
	}

	// if there is no error, it means we already have it
	newCh := NewChannelLink()
	err := newCh.One(bq)

	if err != nil && err != bongo.RecordNotFound {
		return false, err
	}

	if err == nil {
		return true, nil
	}

	return false, nil
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
