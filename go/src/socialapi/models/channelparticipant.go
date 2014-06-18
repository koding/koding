package models

import (
	"errors"
	"fmt"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

// todo Scope function for this struct
// in order not to fetch passive accounts
type ChannelParticipant struct {
	// unique identifier of the channel
	Id int64 `json:"id,string"`

	// Id of the channel
	ChannelId int64 `json:"channelId,string"       sql:"NOT NULL"`

	// Id of the account
	AccountId int64 `json:"accountId,string"       sql:"NOT NULL"`

	// Status of the participant in the channel
	StatusConstant string `json:"statusConstant"   sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// holds troll, unsafe, etc
	MetaBits int16 `json:"-"`

	// date of the user's last access to regarding channel
	LastSeenAt time.Time `json:"lastSeenAt"        sql:"NOT NULL"`

	// Creation date of the channel channel participant
	CreatedAt time.Time `json:"createdAt"          sql:"NOT NULL"`

	// Modification date of the channel participant's status
	UpdatedAt time.Time `json:"updatedAt"          sql:"NOT NULL"`
}

// here is why i did this not-so-good constants
// https://code.google.com/p/go/issues/detail?id=359
const (
	ChannelParticipant_STATUS_ACTIVE              = "active"
	ChannelParticipant_STATUS_LEFT                = "left"
	ChannelParticipant_STATUS_REQUEST_PENDING     = "requestpending"
	ChannelParticipant_Added_To_Channel_Event     = "added_to_channel"
	ChannelParticipant_Removed_From_Channel_Event = "removed_from_channel"
)

func NewChannelParticipant() *ChannelParticipant {
	return &ChannelParticipant{}
}

func (c ChannelParticipant) GetId() int64 {
	return c.Id
}

func (c ChannelParticipant) TableName() string {
	return "api.channel_participant"
}

func (c *ChannelParticipant) BeforeSave() {
	c.LastSeenAt = time.Now().UTC()
}

func (c *ChannelParticipant) BeforeUpdate() {
	c.LastSeenAt = time.Now().UTC()
}

func (c *ChannelParticipant) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *ChannelParticipant) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c ChannelParticipant) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *ChannelParticipant) Create() error {
	if c.ChannelId == 0 {
		return fmt.Errorf("Channel Id is not set %d", c.ChannelId)
	}

	if c.AccountId == 0 {
		return fmt.Errorf("AccountId is not set %d", c.AccountId)
	}

	selector := map[string]interface{}{
		"channel_id": c.ChannelId,
		"account_id": c.AccountId,
	}

	// if err is nil
	// it means we already have that channel
	err := c.One(bongo.NewQS(selector))
	if err == nil {
		c.StatusConstant = ChannelParticipant_STATUS_ACTIVE
		if err := c.Update(); err != nil {
			return err
		}

		if err := bongo.B.PublishEvent(
			ChannelParticipant_Added_To_Channel_Event, c,
		); err != nil {
			// log here
		}

		return nil
	}

	if err != gorm.RecordNotFound {
		return err
	}

	return bongo.B.Create(c)
}

func (c *ChannelParticipant) CreateRaw() error {
	insertSql := "INSERT INTO " +
		c.TableName() +
		` ("channel_id","account_id", "status_constant", "last_seen_at","created_at", "updated_at") ` +
		"VALUES ($1,$2,$3,$4,$5,$6) " +
		"RETURNING ID"

	return bongo.B.DB.CommonDB().
		QueryRow(insertSql, c.ChannelId, c.AccountId, c.StatusConstant, c.LastSeenAt, c.CreatedAt, c.UpdatedAt).
		Scan(&c.Id)
}

func (c *ChannelParticipant) Update() error {
	return bongo.B.Update(c)
}

func (c *ChannelParticipant) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *ChannelParticipant) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *ChannelParticipant) Count(where ...interface{}) (int, error) {
	return bongo.B.Count(c, where...)
}

func (c *ChannelParticipant) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}

func (c *ChannelParticipant) FetchParticipant() error {
	if c.ChannelId == 0 {
		return errors.New("ChannelId is not set")
	}

	if c.AccountId == 0 {
		return errors.New("AccountId is not set")
	}

	selector := map[string]interface{}{
		"channel_id": c.ChannelId,
		"account_id": c.AccountId,
		// "status_constant":     ChannelParticipant_STATUS_ACTIVE,
	}

	err := c.One(bongo.NewQS(selector))
	if err != nil {
		return err
	}

	return nil
}

func (c *ChannelParticipant) FetchUnreadCount() (int, error) {
	cml := NewChannelMessageList()
	return cml.UnreadCount(c)
}

func (c *ChannelParticipant) Delete() error {
	selector := bongo.Partial{
		"account_id": c.AccountId,
		"channel_id": c.ChannelId,
	}

	if err := c.One(bongo.NewQS(selector)); err != nil {
		return err
	}

	if err := bongo.B.UpdatePartial(c,
		bongo.Partial{
			"status_constant": ChannelParticipant_STATUS_LEFT,
		},
	); err != nil {
		return err
	}

	if err := bongo.B.PublishEvent(
		ChannelParticipant_Removed_From_Channel_Event, c,
	); err != nil {
		// log here
	}

	return nil

}

func (c *ChannelParticipant) List() ([]ChannelParticipant, error) {
	var participants []ChannelParticipant

	if c.ChannelId == 0 {
		return participants, errors.New("ChannelId is not set")
	}
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id":      c.ChannelId,
			"status_constant": ChannelParticipant_STATUS_ACTIVE,
		},
	}

	err := bongo.B.Some(c, &participants, query)
	if err != nil {
		return nil, err
	}

	return participants, nil
}

func (c *ChannelParticipant) ListAccountIds(limit int) ([]int64, error) {
	var participants []int64

	if c.ChannelId == 0 {
		return participants, errors.New("ChannelId is not set")
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id":      c.ChannelId,
			"status_constant": ChannelParticipant_STATUS_ACTIVE,
		},
		Pluck:      "account_id",
		Pagination: *bongo.NewPagination(limit, 0),
	}

	err := bongo.B.Some(c, &participants, query)
	if err != nil {
		return nil, err
	}

	return participants, nil
}

func (c *ChannelParticipant) FetchParticipatedChannelIds(a *Account, q *Query) ([]int64, error) {
	if a.Id == 0 {
		return nil, errors.New("Account.Id is not set")
	}

	channelIds := make([]int64, 0)

	// var results []ChannelParticipant
	rows, err := bongo.B.DB.Table(c.TableName()).
		Select("api.channel_participant.channel_id").
		Joins("left join api.channel on api.channel_participant.channel_id = api.channel.id").
		Where("api.channel_participant.account_id = ? and api.channel.type_constant = ? and  api.channel_participant.status_constant = ?", a.Id, q.Type, ChannelParticipant_STATUS_ACTIVE).
		Limit(q.Limit).
		Offset(q.Skip).
		Rows()
	defer rows.Close()
	if err != nil {
		return channelIds, err
	}

	if rows == nil {
		return nil, nil
	}

	var channelId int64
	for rows.Next() {
		rows.Scan(&channelId)
		channelIds = append(channelIds, channelId)
	}

	return channelIds, nil
}

func (c *ChannelParticipant) FetchParticipantCount() (int, error) {
	if c.ChannelId == 0 {
		return 0, errors.New("Channel.Id is not set")
	}

	return c.Count("channel_id = ?", c.ChannelId)
}

func (c *ChannelParticipant) IsParticipant(accountId int64) (bool, error) {
	if c.ChannelId == 0 {
		return false, errors.New("Channel.Id is not set")
	}

	selector := map[string]interface{}{
		"channel_id":      c.ChannelId,
		"account_id":      accountId,
		"status_constant": ChannelParticipant_STATUS_ACTIVE,
	}

	err := c.One(bongo.NewQS(selector))
	if err == nil {
		return true, nil
	}

	if err == gorm.RecordNotFound {
		return false, nil
	}

	return false, err
}
