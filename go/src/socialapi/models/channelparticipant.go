package models

import (
	"fmt"
	"socialapi/request"
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

	// Role of the participant in the channel
	// RoleConstant string `json:"roleConstant"`

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
	ChannelParticipant_STATUS_ACTIVE          = "active"
	ChannelParticipant_STATUS_LEFT            = "left"
	ChannelParticipant_STATUS_BLOCKED         = "blocked"
	ChannelParticipant_STATUS_REQUEST_PENDING = "requestpending"

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
// multiple call of this function will result same
func (c *ChannelParticipant) Create() error {
	// get user defined status constant
	statusConstant := c.StatusConstant
	err := c.FetchParticipant()
	if err != nil && err != bongo.RecordNotFound {
		return err
	}

	// if err is nil
	// it means we already have that user in the channel
	if err == nil {
		// if the participant is already in the channel, and active do nothing
		if c.StatusConstant == ChannelParticipant_STATUS_ACTIVE {
			return nil
		}

		// if the channel participant is blocked dont add it back
		if c.StatusConstant == ChannelParticipant_STATUS_BLOCKED {
			return ErrParticipantBlocked
		}

		// we can update pending participant to active
		c.StatusConstant = statusConstant
		if err := c.Update(); err != nil {
			return err
		}

	} else {
		if err := bongo.B.Create(c); err != nil {
			return err
		}
	}

	return nil
}

func (c *ChannelParticipant) CreateRaw() error {
	insertSql := "INSERT INTO " +
		c.BongoName() +
		` ("channel_id","account_id", "status_constant", "last_seen_at","created_at", "updated_at") ` +
		"VALUES ($1,$2,$3,$4,$5,$6) " +
		"RETURNING ID"

	return bongo.B.DB.CommonDB().
		QueryRow(insertSql, c.ChannelId, c.AccountId, c.StatusConstant, c.LastSeenAt, c.CreatedAt, c.UpdatedAt).
		Scan(&c.Id)
}

// Tests are done.
func (c *ChannelParticipant) FetchParticipant() error {
	if c.ChannelId == 0 {
		return ErrChannelIdIsNotSet
	}

	if c.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	selector := map[string]interface{}{
		"channel_id": c.ChannelId,
		"account_id": c.AccountId,
	}

	return c.fetchParticipant(selector)
}

// Tests are done.
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
	return c.One(bongo.NewQS(selector))
}

// Tests are done in channelmessagelist.
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

	return nil
}

// Block changes the status of the participant to blocked
func (c *ChannelParticipant) Block() error {
	if err := c.FetchParticipant(); err != nil {
		return err
	}

	c.StatusConstant = ChannelParticipant_STATUS_BLOCKED
	if err := c.Update(); err != nil {
		return err
	}

	return nil
}

// Unblock changes the status of the participant to left
func (c *ChannelParticipant) Unblock() error {
	// this is a convenient function for unblocking, normally it should just
	// mark the user as left, and they can re-join to that channel again
	return c.Delete()
}

func (c *ChannelParticipant) List(q *request.Query) ([]ChannelParticipant, error) {
	var participants []ChannelParticipant

	if c.ChannelId == 0 {
		return participants, ErrChannelIdIsNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id":      c.ChannelId,
			"status_constant": ChannelParticipant_STATUS_ACTIVE,
		},
	}

	if q.Limit > 0 {
		query.Pagination.Limit = q.Limit
	}

	if len(q.Sort) > 0 {
		query.Sort = q.Sort
	}

	if q.Skip > 0 {
		query.Pagination.Skip = q.Skip
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
		return participants, ErrChannelIdIsNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id":      c.ChannelId,
			"status_constant": ChannelParticipant_STATUS_ACTIVE,
		},
		Pluck: "account_id",
	}

	if limit != 0 {
		query.Pagination = *bongo.NewPagination(limit, 0)
	}

	// do not include troll content
	query.AddScope(RemoveTrollContent(c, false))

	err := bongo.B.Some(c, &participants, query)
	if err != nil {
		return nil, err
	}

	return participants, nil
}

// FetchAllParticipatedChannelIds fetches all active channel ids that are
// participated by given account
func (c *ChannelParticipant) FetchAllParticipatedChannelIds(accountId int64) ([]int64, error) {
	if accountId == 0 {
		return nil, ErrAccountIdIsNotSet
	}

	var channelIds []int64

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id":      accountId,
			"status_constant": ChannelParticipant_STATUS_ACTIVE,
		},
		Pluck: "channel_id",
	}

	err := bongo.B.Some(c, &channelIds, query)
	if err != nil {
		return nil, err
	}

	return channelIds, nil
}

// FetchAllParticipatedChannelIdsInGroup fetches all channel ids of an account
// within given group
func (c *ChannelParticipant) FetchAllParticipatedChannelIdsInGroup(accountId int64, groupName string) ([]int64, error) {
	if accountId == 0 {
		return nil, ErrAccountIdIsNotSet
	}

	// var results []ChannelParticipant
	query := getParticipatedChannelsQuery(accountId, groupName)

	rows, err := query.Rows()
	if err != nil {
		return nil, err
	}

	if rows == nil {
		return nil, nil
	}
	defer rows.Close()

	channelIds := make([]int64, 0)
	var channelId int64
	for rows.Next() {
		rows.Scan(&channelId)
		channelIds = append(channelIds, channelId)
	}

	return channelIds, nil
}

func getParticipatedChannelsQuery(accountId int64, groupName string) *gorm.DB {
	c := NewChannelParticipant()

	return bongo.B.DB.
		Model(c).
		Table(c.BongoName()).
		Select("api.channel_participant.channel_id").
		Joins(
			`left join api.channel on
		 api.channel_participant.channel_id = api.channel.id`).
		Where(
			`api.channel_participant.account_id = ? and
		 api.channel.group_name = ? and
		 api.channel_participant.status_constant = ?`,
			accountId,
			groupName,
			ChannelParticipant_STATUS_ACTIVE,
		)
}

func (c *ChannelParticipant) ParticipatedChannelCount(a *Account, q *request.Query) (*CountResponse, error) {
	if a.Id == 0 {
		return nil, ErrAccountIdIsNotSet
	}

	query := getParticipatedChannelsQuery(a.Id, q.GroupName)
	// filter channels according to given type
	query = query.Where("api.channel.type_constant = ?", q.Type)

	// add exempt clause if needed
	if !q.ShowExempt {
		query = query.Where("api.channel.meta_bits = ?", Safe)
	}

	var count int
	query = query.Count(&count)
	if query.Error != nil {
		return nil, query.Error
	}

	res := new(CountResponse)
	res.TotalCount = count

	return res, nil
}

func (c *ChannelParticipant) FetchParticipatedTypedChannelIds(a *Account, q *request.Query) ([]int64, error) {
	if a.Id == 0 {
		return nil, ErrAccountIdIsNotSet
	}

	// var results []ChannelParticipant
	query := getParticipatedChannelsQuery(a.Id, q.GroupName)

	// filter channels according to given type
	query = query.Where("api.channel.type_constant = ?", q.Type)

	// add exempt clause if needed
	if !q.ShowExempt {
		query = query.Where("api.channel.meta_bits <> ?", Troll)
	}

	rows, err := query.
		Limit(q.Limit).
		Offset(q.Skip).
		Rows()
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	if rows == nil {
		return nil, nil
	}

	channelIds := make([]int64, 0)

	var channelId int64
	for rows.Next() {
		rows.Scan(&channelId)
		channelIds = append(channelIds, channelId)
	}

	// if this is the first query for listing the channels
	// add default channels into the result set
	if q.Skip == 0 {
		defaultChannels, err := c.fetchDefaultChannels(q)
		if err != nil {
			fmt.Println(err.Error())
		} else {
			for _, item := range channelIds {
				defaultChannels = append(defaultChannels, item)
			}
			return defaultChannels, nil
		}
	}

	return channelIds, nil
}

// fetchDefaultChannels fetchs the default channels of the system, currently we
// have two different default channels, group channel and announcement channel
// that everyone in the system should be a member of them, they cannot opt-out,
// they will be able to see the contents of it, they will get the notifications,
// they will see the unread count
func (c *ChannelParticipant) fetchDefaultChannels(q *request.Query) ([]int64, error) {
	var channels []Channel
	channel := NewChannel()
	res := bongo.B.DB.
		Model(channel).
		Table(channel.BongoName()).
		Where(
			"group_name = ? AND type_constant IN (?)",
			q.GroupName,
			[]string{Channel_TYPE_GROUP, Channel_TYPE_ANNOUNCEMENT},
		).
		// Order("type_constant ASC"). // order by increases query plan by x12K
		// no need to traverse all database, limit with a known count
		Limit(2).
		// only select ids
		Find(&channels)

	if err := bongo.CheckErr(res); err != nil {
		return nil, err
	}

	// be sure that this account is a participant of default channels
	if err := c.ensureParticipation(q.AccountId, channels); err != nil {
		return nil, err
	}

	// order channels in memory instead of ordering them in db
	channelIds := make([]int64, len(channels))
	switch len(channels) {
	case 1:
		// we can have one result if group doesnt have announcement channel
		channelIds[0] = channels[0].Id
	case 2:
		for _, channel := range channels {
			if channel.TypeConstant == Channel_TYPE_GROUP {
				channelIds[0] = channel.Id
			}
			if channel.TypeConstant == Channel_TYPE_ANNOUNCEMENT {
				channelIds[1] = channel.Id
			}
		}
	default:
		return nil, nil
	}

	return channelIds, nil
}

func (c *ChannelParticipant) ensureParticipation(accountId int64, channels []Channel) error {
	for _, channel := range channels {
		cp := NewChannelParticipant()
		cp.ChannelId = channel.Id
		cp.AccountId = accountId
		// create is idempotent, multiple calls wont cause any problem, if the
		// user is already a participant, will return as if a successful request
		if err := cp.Create(); err != nil {
			return err
		}
	}

	return nil
}

// FetchParticipantCount fetchs the participant count in the channel
// if there is no participant in the channel, then returns zero value
//
// Tests are done.
func (c *ChannelParticipant) FetchParticipantCount() (int, error) {
	if c.ChannelId == 0 {
		return 0, ErrChannelIdIsNotSet
	}

	return c.Count("channel_id = ? and status_constant = ?", c.ChannelId, ChannelParticipant_STATUS_ACTIVE)
}

// Tests are done.
func (c *ChannelParticipant) IsParticipant(accountId int64) (bool, error) {
	c.StatusConstant = ChannelParticipant_STATUS_ACTIVE

	return c.checkAccountStatus(accountId)
}

func (c *ChannelParticipant) IsInvited(accountId int64) (bool, error) {
	c.StatusConstant = ChannelParticipant_STATUS_REQUEST_PENDING

	return c.checkAccountStatus(accountId)
}

func (c *ChannelParticipant) checkAccountStatus(accountId int64) (bool, error) {
	if accountId == 0 {
		return false, nil
	}

	if c.ChannelId == 0 {
		return false, ErrChannelIdIsNotSet
	}

	if c.StatusConstant == "" {
		c.StatusConstant = ChannelParticipant_STATUS_ACTIVE
	}

	selector := map[string]interface{}{
		"channel_id":      c.ChannelId,
		"account_id":      accountId,
		"status_constant": c.StatusConstant,
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
//
// Tests are done.
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

// Tests are done.
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

// Tests are done.
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

func (c *ChannelParticipant) RawUpdateLastSeenAt(t time.Time) error {
	if c.Id == 0 {
		return ErrIdIsNotSet
	}

	query := fmt.Sprintf("UPDATE %s SET last_seen_at = ? WHERE id = ?", c.BongoName())
	if err := bongo.B.DB.Exec(query, t, c.Id).Error; err != nil {
		return err
	}

	go bongo.B.PublishEvent("channel_glanced", c)

	return nil
}

func (c *ChannelParticipant) Glance() error {
	c.LastSeenAt = time.Now().UTC()

	if err := c.Update(); err != nil {
		return err
	}

	go bongo.B.PublishEvent("channel_glanced", c)

	return nil
}
