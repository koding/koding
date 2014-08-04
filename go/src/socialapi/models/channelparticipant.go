package models

import (
	"errors"
	"fmt"
	"socialapi/request"
	"time"

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
	MetaBits MetaBits `json:"metaBits"`

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
	return &ChannelParticipant{
		StatusConstant: ChannelParticipant_STATUS_ACTIVE,
		LastSeenAt:     time.Now().UTC(),
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	}
}

// Create creates a participant in the db as active
// multiple call of this function will result
func (c *ChannelParticipant) Create() error {
	err := c.FetchParticipant()

	// if err is nil
	// it means we already have that user in the channel
	if err == nil {
		// if the participant is already in the channel, and active do nothing
		if c.StatusConstant == ChannelParticipant_STATUS_ACTIVE {
			return nil
		}

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

	if err != bongo.RecordNotFound {
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

func (c *ChannelParticipant) FetchParticipant() error {

	selector := map[string]interface{}{
		"channel_id": c.ChannelId,
		"account_id": c.AccountId,
	}

	return c.fetchParticipant(selector)
}

func (c *ChannelParticipant) FetchActiveParticipant() error {
	selector := map[string]interface{}{
		"channel_id":      c.ChannelId,
		"account_id":      c.AccountId,
		"status_constant": ChannelParticipant_STATUS_ACTIVE,
	}

	return c.fetchParticipant(selector)
}

func (c *ChannelParticipant) fetchParticipant(selector map[string]interface{}) error {
	if c.ChannelId == 0 {
		return ErrChannelIdIsNotSet
	}

	if c.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	// TODO do we need to add isExempt scope here?
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
	if err := c.FetchParticipant(); err != nil {
		return err
	}

	c.StatusConstant = ChannelParticipant_STATUS_LEFT
	if err := c.Update(); err != nil {
		return err
	}

	if err := bongo.B.PublishEvent(
		ChannelParticipant_Removed_From_Channel_Event, c,
	); err != nil {
		// log here
	}

	return nil

}

func (c *ChannelParticipant) List(q *request.Query) ([]ChannelParticipant, error) {
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

	// add filter for troll content
	query.AddScope(RemoveTrollContent(c, q.ShowExempt))

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

	// do not include troll content
	query.AddScope(RemoveTrollContent(c, false))

	err := bongo.B.Some(c, &participants, query)
	if err != nil {
		return nil, err
	}

	return participants, nil
}

func (c *ChannelParticipant) FetchParticipatedChannelIds(a *Account, q *request.Query) ([]int64, error) {
	if a.Id == 0 {
		return nil, errors.New("Account.Id is not set")
	}

	channelIds := make([]int64, 0)

	// var results []ChannelParticipant
	query := bongo.B.DB.
		Model(c).
		Table(c.TableName()).
		Select("api.channel_participant.channel_id").
		Joins(
		`left join api.channel on
		 api.channel_participant.channel_id = api.channel.id`).
		Where(
		`api.channel_participant.account_id = ? and
		 api.channel.group_name = ? and
		 api.channel.type_constant = ? and
		 api.channel_participant.status_constant = ?`,
		a.Id,
		q.GroupName,
		q.Type,
		ChannelParticipant_STATUS_ACTIVE,
	)

	// add exempt clause if needed
	if !q.ShowExempt {
		query = query.Where("api.channel.meta_bits = ?", Safe)
	}

	rows, err := query.Limit(q.Limit).
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
		return 0, errors.New("channel Id is not set")
	}

	return c.Count("channel_id = ? and status_constant = ?", c.ChannelId, ChannelParticipant_STATUS_ACTIVE)
}

func (c *ChannelParticipant) IsParticipant(accountId int64) (bool, error) {
	if c.ChannelId == 0 {
		return false, ErrChannelIdIsNotSet
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

	if err == bongo.RecordNotFound {
		return false, nil
	}

	return false, err
}

// Put them all behind an interface
// channels, messages, lists, participants, etc
func (c *ChannelParticipant) MarkIfExempt() error {
	isExempt, err := c.isExempt()
	if err != nil {
		return err
	}

	if isExempt {
		c.MetaBits.Mark(Troll)
	}

	return nil
}

func (c *ChannelParticipant) isExempt() (bool, error) {
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

	if account == nil {
		return false, fmt.Errorf("account is nil, accountId:%d", accountId)
	}

	if account.IsTroll {
		return true, nil
	}

	return false, nil
}

func (c *ChannelParticipant) getAccountId() (int64, error) {
	if c.AccountId != 0 {
		return c.AccountId, nil
	}

	if c.Id == 0 {
		return 0, fmt.Errorf("couldnt find accountId from content %+v", c)
	}

	cp := NewChannelParticipant()
	if err := cp.ById(c.Id); err != nil {
		return 0, err
	}

	return cp.AccountId, nil
}
