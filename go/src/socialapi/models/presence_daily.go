package models

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/request"
	"strconv"
	"time"

	"github.com/koding/bongo"
)

// PresenceDaily holds presence info on day granuality
type PresenceDaily struct {
	// Id unique identifier of the channel
	Id int64 `json:"id,string"`

	// AccountId holds the active users info
	AccountId int64 `json:"accountId,string"         sql:"NOT NULL"`

	// Name of the group
	GroupName string `json:"name" sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Creation date of the record
	CreatedAt time.Time `json:"createdAt"            sql:"NOT NULL"`

	// IsProcessed did we processed the record?
	IsProcessed bool `json:"isProcessed"`
}

type accountRes struct {
	AccountId int64
}

// ActiveAccountResponse holds the active accounts and deleted account count
// if account in postgres doesn't exist in mongo, then that account will be counted as deleted account
type ActiveAccountResponse struct {
	Accounts     []mongomodels.Account `json:"accounts"`
	DeletedCount int                   `json:"deletedCount"`
}

// CountDistinctByGroupName counts distinct account ids
func (a *PresenceDaily) CountDistinctByGroupName(groupName string) (int, error) {
	return a.countDistinctByGroupNameAndStatus(groupName, false)
}

// CountDistinctProcessedByGroupName counts processed distinct account ids
func (a *PresenceDaily) CountDistinctProcessedByGroupName(groupName string) (int, error) {
	return a.countDistinctByGroupNameAndStatus(groupName, true)
}

// countDistinctByGroupName counts distinct account ids
func (a *PresenceDaily) countDistinctByGroupNameAndStatus(groupName string, status bool) (int, error) {
	res := struct {
		Count int
	}{}

	return res.Count, bongo.B.DB.
		Table(a.BongoName()).
		Model(&PresenceDaily{}).
		Where("group_name = ? and is_processed = ?", groupName, status).
		Select("count(distinct account_id)").
		Scan(&res).Error
}

// ProcessByGroupName sets items as processed by their group's name
func (a *PresenceDaily) ProcessByGroupName(groupName string) error {
	// i have tried to use it ORM way but gorm has bugs that does not update multiple values at once
	sql := "UPDATE " + a.BongoName() + " SET is_processed=true WHERE group_name = ? and is_processed = false"
	return bongo.B.DB.Exec(sql, groupName).Error
}

// DeleteByGroupName deletes items by their group's name
func (a *PresenceDaily) DeleteByGroupName(groupName string) error {
	sql := "DELETE FROM " + a.BongoName() + " WHERE group_name = ?"
	return bongo.B.DB.Exec(sql, groupName).Error
}

// FetchActiveAccounts fetches active acounts that are not processed yet
func (a *PresenceDaily) FetchActiveAccounts(query *request.Query) (*ActiveAccountResponse, error) {
	res := make([]accountRes, 0)
	err := bongo.B.DB.
		Table(a.BongoName()).
		Model(&PresenceDaily{}).
		Where("group_name = ? and is_processed = ?", query.GroupName, false).
		Order("created_at", true).
		Select("distinct account_id, created_at").
		Limit(query.Limit).
		Offset(query.Skip).
		Scan(&res).Error

	if err != nil {
		return nil, err
	}

	ids := make([]string, len(res))
	for i, id := range res {
		ids[i] = strconv.FormatInt(id.AccountId, 10)
	}

	acc, err := modelhelper.GetAccountBySocialApiIds(ids...)
	if err != nil {
		return nil, err
	}

	return &ActiveAccountResponse{
		Accounts:     acc,
		DeletedCount: len(ids) - len(acc),
	}, nil
}
