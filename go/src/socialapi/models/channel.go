package models

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"strings"
	"time"

	mgo "gopkg.in/mgo.v2"

	"socialapi/request"

	"github.com/hashicorp/go-multierror"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Channel struct {
	// unique identifier of the channel
	Id int64 `json:"id,string"`

	// Token holds the uuid for interoperability with the bongo-client
	Token string `json:"token"`

	// Name of the channel
	Name string `json:"name"                         sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Creator of the channel
	CreatorId int64 `json:"creatorId,string"         sql:"NOT NULL"`

	// Name of the group which channel is belong to
	GroupName string `json:"groupName"               sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Purpose of the channel
	Purpose string `json:"purpose"`

	// Type of the channel
	TypeConstant string `json:"typeConstant"         sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Privacy constant of the channel
	PrivacyConstant string `json:"privacyConstant"   sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// MetaBits holds meta bit information about the channel
	MetaBits MetaBits `json:"metaBits"`

	// Extra data storage
	Payload gorm.Hstore `json:"payload"`

	// Creation date of the channel
	CreatedAt time.Time `json:"createdAt"            sql:"NOT NULL"`

	// Modification date of the channel
	UpdatedAt time.Time `json:"updatedAt"            sql:"NOT NULL"`

	// Deletion date of the channel
	DeletedAt time.Time `json:"deletedAt"`
}

// to-do check for allowed channels
const (
	// TYPES
	Channel_TYPE_GROUP         = "group"
	Channel_TYPE_COLLABORATION = "collaboration"
	Channel_TYPE_DEFAULT       = "default"
	// Privacy
	Channel_PRIVACY_PUBLIC  = "public"
	Channel_PRIVACY_PRIVATE = "private"
	// Koding Group Name
	Channel_KODING_NAME = "koding"
)

// NewChannel inits channel
// fills required constants what necessary is as default
//
// Tests are done
func NewChannel() *Channel {
	return &Channel{
		Name:            "channel-" + RandomName(),
		GroupName:       Channel_KODING_NAME,
		TypeConstant:    Channel_TYPE_DEFAULT,
		PrivacyConstant: Channel_PRIVACY_PRIVATE,
	}
}

// NewCollaborationChannel takes the creator id and group name of the channel as arguments
// sets required content of the channel
// and sets constants as 'private'
//
// Tests are done
func NewCollaborationChannel(creatorId int64, groupName string) *Channel {
	return NewPrivateChannel(creatorId, groupName, Channel_TYPE_COLLABORATION)
}

// NewPrivateChannel takes the creator id, group name of the channel and channel type as arguments
// sets required content of the channel
// and sets constants as 'private'
//
// Tests are done
func NewPrivateChannel(creatorId int64, groupName string, typeConstant string) *Channel {
	c := NewChannel()
	c.GroupName = groupName
	c.CreatorId = creatorId
	c.Name = RandomName()
	c.TypeConstant = typeConstant
	c.PrivacyConstant = Channel_PRIVACY_PRIVATE
	c.Purpose = ""
	return c
}

// Create creates a channel in db
// some fields of the channel must be filled (should not be empty)
//
// Tests are done..
func (c *Channel) Create() error {
	if c.Name == "" || c.GroupName == "" || c.TypeConstant == "" || c.CreatorId == 0 {
		return fmt.Errorf("Validation failed %s - %s - %s - %d", c.Name, c.GroupName, c.TypeConstant, c.CreatorId)
	}

	// golang returns -1 if item not in the string
	if strings.Contains(c.Name, " ") {
		return fmt.Errorf("Channel name %q has empty space in it", c.Name)
	}

	// if channel type is not group or following try to create it
	if c.TypeConstant != Channel_TYPE_GROUP {
		return idempotentCreate(c)
	}

	// selectors helps database to create what we need
	var selector map[string]interface{}

	switch c.TypeConstant {
	case Channel_TYPE_GROUP:
		selector = map[string]interface{}{
			"group_name":    c.GroupName,
			"type_constant": c.TypeConstant,
		}
	case Channel_TYPE_DEFAULT:
		selector = map[string]interface{}{
			"group_name":    c.GroupName,
			"type_constant": c.TypeConstant,
		}
	}

	// if err is nil
	// it means we already have that channel
	err := c.One(bongo.NewQS(selector))
	if err == nil {
		// this means, we already have the channel in the db, it is safe to return
		return nil
	}

	// if error is not NotFound, return it
	if err != bongo.RecordNotFound {
		return err
	}

	// if we couldnt find the record in the db, then create it
	return idempotentCreate(c)
}

func idempotentCreate(c *Channel) error {
	err := bongo.B.Create(c)
	if err == nil {
		return nil
	}

	if !IsUniqueConstraintError(err) {
		return err
	}

	q := &request.Query{
		GroupName: c.GroupName,
		Type:      c.TypeConstant,
		Name:      c.Name,
	}

	// ignore error for fetch request. c is modified in ByName, so if we find
	// the channel in db, c will have it assigned
	_, _ = c.ByName(q)
	return err
}

// AddParticipant adds a user(participant) to the channel
// if account is already in the channel,
// it won't add again user to channel as participant
//
// Tests are done.
func (c *Channel) AddParticipant(participantId int64) (*ChannelParticipant, error) {
	if c.Id == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	if c.CreatorId == 0 {
		return nil, ErrCreatorIdIsNotSet
	}

	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	cp.AccountId = participantId

	// get participant from db if it is created before
	err := cp.FetchParticipant()
	// suppress not found error
	if err != nil && err != bongo.RecordNotFound {
		return nil, err
	}

	// if we have this record in DB
	if cp.Id != 0 {
		// if the user is already actively participant of a channel
		// return it early
		if cp.StatusConstant == ChannelParticipant_STATUS_ACTIVE {
			// TODO, why we are returning an error here?
			return nil, ErrAccountIsAlreadyInTheChannel
		}

		cp.StatusConstant = ChannelParticipant_STATUS_ACTIVE
		if err := cp.Update(); err != nil {
			return nil, err
		}

		return cp, nil
	}

	cp.StatusConstant = ChannelParticipant_STATUS_ACTIVE

	if err := cp.Create(); err != nil {
		return nil, err
	}

	return cp, nil
}

// RemoveParticipant removes the user(participant) from the channel
// if user is already removed from the channel, will return with success
//
// Tests are done.
func (c *Channel) RemoveParticipant(participantIds ...int64) error {
	return c.removeParticipation(ChannelParticipant_STATUS_LEFT, participantIds...)
}

// BlockParticipant blocks the user(participant) from reaching to a channel
func (c *Channel) BlockParticipant(participantIds ...int64) error {
	return c.removeParticipation(ChannelParticipant_STATUS_BLOCKED, participantIds...)
}

func (c *Channel) removeParticipation(typeConstant string, participantIds ...int64) error {
	if c.Id == 0 {
		return ErrChannelIdIsNotSet
	}

	var participants []*ChannelParticipant
	pe := NewParticipantEvent()
	pe.Id = c.Id
	pe.ChannelToken = c.Token

	for _, participantId := range participantIds {
		cp := NewChannelParticipant()
		cp.ChannelId = c.Id
		cp.AccountId = participantId

		err := cp.FetchParticipant()
		// if user is not in this channel, do nothing
		if err == bongo.RecordNotFound {
			continue
		}

		if err != nil {
			return err
		}

		participants = append(participants, cp)

		acc, err := Cache.Account.ById(participantId)
		if err == nil {
			pe.Tokens = append(pe.Tokens, acc.Token)
		}

		if cp.StatusConstant == typeConstant {
			continue
		}

		// if status of the participant is left or blocked (participant is not in
		// the channel), do nothing
		if cp.StatusConstant == ChannelParticipant_STATUS_BLOCKED &&
			typeConstant == ChannelParticipant_STATUS_LEFT {
			continue
		}

		cp.StatusConstant = typeConstant
		if err := cp.Update(); err != nil {
			return err
		}
	}

	pe.Participants = participants
	bongo.B.PublishEvent(ChannelParticipant_Removed_From_Channel_Event, pe)

	return nil
}

// FetchParticipantIds gives ID of the accounts which ids are active in the channel
func (c *Channel) FetchParticipantIds(q *request.Query) ([]int64, error) {
	var participantIds []int64

	if c.Id == 0 {
		return participantIds, ErrChannelIdIsNotSet
	}

	cp := NewChannelParticipant()
	bq := bongo.B.DB.
		Table(cp.BongoName()).
		Where("channel_id = ?", c.Id).
		Where("status_constant in (?)",
			[]string{ChannelParticipant_STATUS_ACTIVE,
				ChannelParticipant_STATUS_REQUEST_PENDING,
			})

	if !q.ShowExempt {
		bq = bq.Where("meta_bits <> ?", Troll)

	}
	res := bq.Pluck("account_id", &participantIds)

	if err := bongo.CheckErr(res); err != nil {
		return nil, err
	}

	return participantIds, nil
}

func (c *Channel) FetchParticipants(q *request.Query) ([]Account, error) {
	var accounts []Account
	ids, err := c.FetchParticipantIds(q)
	if err != nil {
		return accounts, err
	}

	return NewAccount().FetchByIds(ids)
}

func (c *Channel) FetchChannelParticipants() ([]ChannelParticipant, error) {
	if c.Id == 0 {
		return nil, ErrChannelIdIsNotSet
	}
	var participants []ChannelParticipant

	selector := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": c.Id,
		},
	}

	cp := NewChannelParticipant()
	if err := cp.Some(&participants, selector); err != nil {
		return nil, err
	}

	if len(participants) == 0 {
		return nil, bongo.RecordNotFound
	}

	return participants, nil
}

// DeleteChannelParticipants fetches the participants og the channel and
// deletes all the participant of the channel
func (c *Channel) DeleteChannelParticipants() error {
	participants, err := c.FetchChannelParticipants()
	if err != nil && err != bongo.RecordNotFound {
		return err
	}

	var errs *multierror.Error

	for _, participant := range participants {
		err = participant.DeleteForce()
		if err != nil && err != bongo.RecordNotFound {
			errs = multierror.Append(errs, err)
		}
	}

	return errs.ErrorOrNil()
}

// FetchChannelIdByNameAndGroupName fetchs the first ID of the channel via channel name & group name
//
// Tests are done..
func (c *Channel) FetchChannelIdByNameAndGroupName(name, groupName string) (int64, error) {
	if name == "" {
		return 0, ErrNameIsNotSet
	}

	if groupName == "" {
		return 0, ErrGroupNameIsNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"name":       name,
			"group_name": groupName,
		},
		Pagination: *bongo.NewPagination(1, 0),
		Pluck:      "id",
	}
	var ids []int64
	if err := c.Some(&ids, query); err != nil {
		return 0, err
	}

	if ids == nil {
		return 0, bongo.RecordNotFound
	}

	if len(ids) == 0 {
		return 0, bongo.RecordNotFound
	}

	return ids[0], nil
}

// ByName fetches the channel by name, type_constant and group_name, it doesnt
// have the best name, but evolved to this situation :/
func (c *Channel) ByName(q *request.Query) (Channel, error) {
	var channel Channel

	if q.GroupName == "" {
		return channel, ErrGroupNameIsNotSet
	}

	if q.Type == "" {
		return channel, errors.New("type_constant is required.")
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name":    q.GroupName,
			"type_constant": q.Type,
			"name":          q.Name,
		},
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	query.AddScope(RemoveTrollContent(c, q.ShowExempt))

	err := c.One(query)
	if err != nil && err != bongo.RecordNotFound {
		return channel, err
	}

	return *c, nil
}

func (c *Channel) List(q *request.Query) ([]Channel, error) {
	if q.GroupName == "" {
		return nil, ErrGroupNameIsNotSet
	}

	var channels []Channel

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name": q.GroupName,
		},
		Sort: map[string]string{
			"created_at": "DESC",
		},
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	if q.Type != "" {
		query.Selector["type_constant"] = q.Type
	}

	query.AddScope(RemoveTrollContent(c, q.ShowExempt))

	err := c.Some(&channels, query)
	if err != nil {
		return nil, err
	}

	if channels == nil {
		return make([]Channel, 0), nil
	}

	return channels, nil
}

func (c *Channel) FetchAllChannelsOfGroup() ([]Channel, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name": c.GroupName,
		},
	}

	pairs := make(map[string]interface{}, 0)
	pairs["type_constant"] = Channel_TYPE_GROUP

	query.AddScope(ExcludeFields(pairs))

	var channels []Channel
	err := c.Some(&channels, query)
	if err != nil {
		return nil, err
	}

	return channels, nil
}

// CanOpen checks permissions for channels
// group channels can be opened by everyone
// But private message channel just CanOpened by participant
//
// Tests are done.
func (c *Channel) CanOpen(accountId int64) (bool, error) {
	if c.Id == 0 {
		return false, ErrChannelIdIsNotSet
	}

	if c.CreatorId == 0 {
		return false, ErrCreatorIdIsNotSet
	}

	// check if user is a participant
	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	isParticipant, err := cp.IsParticipant(accountId)
	if err != nil {
		return false, err
	}

	// if already participant, return success
	if isParticipant {
		return true, nil
	}

	// anyone can read group activity
	if !c.IsPubliclyAccessibleInGroup() {
		return false, nil
	}

	// special cases for koding group, no need to check with db
	if c.GroupName == Channel_KODING_NAME {
		return true, nil
	}

	if c.TypeConstant == Channel_TYPE_GROUP { // do not cause an infite loop
		return false, nil
	}

	// if we get this far, users trying to access to a channel where:
	// * they are in a group different from koding
	// ** trying to follow/read a topic content
	groupChan := NewChannel()
	if err := groupChan.FetchGroupChannel(c.GroupName); err != nil {
		return false, err
	}

	// if one can open group channel, can read publicly accessible channels
	return groupChan.CanOpen(accountId)
}

// IsPubliclyAccessibleInGroup checks if current channel is a publicly
// accessible channel within a group
//
// Do not mess here, it is highly discauraged to touch this function if you dont
// know what you are doing
func (c *Channel) IsPubliclyAccessibleInGroup() bool {
	// anyone can read group activity
	return c.TypeConstant == Channel_TYPE_GROUP
}

func (c *Channel) isExempt() (bool, error) {
	// return early if channel is already exempt
	if c.MetaBits.Is(Troll) {
		return true, nil
	}

	accountId, err := c.getAccountId()
	if err != nil {
		return false, err
	}

	account, err := ResetAccountCache(accountId)
	if err != nil {
		return false, err
	}

	if account.IsTroll {
		return true, nil
	}

	return false, nil
}

// getAccountId checks the channel that has a creator id or not
// and returns id of creator of the channel
//
// Tests are done
func (c *Channel) getAccountId() (int64, error) {
	if c.CreatorId != 0 {
		return c.CreatorId, nil
	}

	if c.Id == 0 {
		return 0, ErrChannelIdIsNotSet
	}

	cn := NewChannel()
	if err := cn.ById(c.Id); err != nil {
		return 0, err
	}

	return cn.CreatorId, nil
}

// FetchParticipant simply fetch the participants from the channel
// if participant leaves from the channel
// just marking status constant as LEFT
//
// Tests are done
func (c *Channel) FetchParticipant(accountId int64) (*ChannelParticipant, error) {
	if c.Id == 0 {
		return nil, ErrIdIsNotSet
	}

	if accountId == 0 {
		return nil, ErrAccountIdIsNotSet
	}

	cp := NewChannelParticipant()
	cp.AccountId = accountId
	cp.ChannelId = c.Id
	if err := cp.FetchParticipant(); err != nil {
		return nil, err
	}

	return cp, nil
}

// IsParticipant controls that the participant is in the channel or not
//
// Tests are done.
func (c *Channel) IsParticipant(accountId int64) (bool, error) {
	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	return cp.IsParticipant(accountId)
}

func (c *Channel) FetchGroupChannel(groupName string) error {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name":    groupName,
			"type_constant": Channel_TYPE_GROUP,
		},
	}

	err := c.One(query)
	if err == bongo.RecordNotFound {
		return ErrGroupNotFound
	}

	return err
}

// IsGroup checks if the channel type is a group channel
func (c *Channel) IsGroup() bool {
	return c.TypeConstant == Channel_TYPE_GROUP
}

// FetchChannelsWithPagination fetches the channels with pagination via limit & offset
func FetchChannelsWithPagination(limit, offset int) ([]Channel, error) {
	acc := &Channel{}
	var channels []Channel
	query := &bongo.Query{
		Pagination: *bongo.NewPagination(limit, offset),
	}
	if err := acc.Some(&channels, query); err != nil {
		return nil, err
	}

	return channels, nil
}

// DeleteChannelsIfGroupNotInMongo fetches all channels in postgres with pagination.
// Then checks the group names in mongoDB.
// If groupname doesn't exist in mongoDB then deletes that channel and its participants
// If groupname exists in mongoDB, do nothing.
func DeleteChannelsIfGroupNotInMongo() error {
	var errs *multierror.Error

	limit := 100
	offset := 0

	for {
		// counter := 0
		channels, err := FetchChannelsWithPagination(limit, offset)
		if err != nil {
			errs = multierror.Append(errs, err)
		}

		for _, channel := range channels {
			_, err := modelhelper.GetGroup(channel.GroupName)
			// if group already exists in mongo, then we don't need to fecth the same data
			// while fetching channels
			if err == nil {
				offset++
				continue
			}
			// if error is not nil and equal to record not found
			// then remove the channel and its participants in postgre
			if err != nil && err == mgo.ErrNotFound {
				if err = channel.DeleteWithParticipantsForce(); err != nil {
					errs = multierror.Append(errs, err)
				}
			} else {
				errs = multierror.Append(errs, err)
				offset++
			}
		}

		// This check provide us to break the loop if there is no data left that need
		// to be processed fetch tolerance is limit, if fetched channels count is
		// less than limited number then break the loop.
		if len(channels) < limit {
			break
		}
	}

	return errs.ErrorOrNil()
}
