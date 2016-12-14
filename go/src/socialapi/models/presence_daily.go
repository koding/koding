package models

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/request"
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

type countRes struct {
	Count int
}

type accountRes struct {
	AccountId int64
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
	res := &countRes{}
	return res.Count, bongo.B.DB.
		Table(a.BongoName()).
		Model(&PresenceDaily{}).
		Where("group_name = ? and is_processed = ?", groupName, status).
		Select("count(distinct account_id)").
		Scan(res).Error
}

// ProcessByGroupName deletes items by their group's name from db
func (a *PresenceDaily) ProcessByGroupName(groupName string) error {
	// i have tried to use it ORM way but gorm has bugs that does not update multiple values at once
	sql := "UPDATE " + a.BongoName() + " SET is_processed=true WHERE group_name = ? and is_processed = false"
	return bongo.B.DB.Exec(sql, groupName).Error
}

// FetchActiveAccounts fetches active acounts that are not processed yet
func (a *PresenceDaily) FetchActiveAccounts(query *request.Query) ([]mongomodels.Account, error) {
	res := make([]accountRes, 0)
	err := bongo.B.DB.
		Table(a.BongoName()).
		Model(&PresenceDaily{}).
		Where("group_name = ? and is_processed = ?", query.GroupName, false).
		Select("distinct account_id").
		Limit(query.Limit).
		Offset(query.Skip).
		Scan(res).Error

	if err != nil {
		return nil, err
	}

	ids := make([]int64, 0, len(res))
	for i, id := range res {
		ids[i] = id.AccountId
	}

	return modelhelper.GetAccountBySocialApiIds(ids...)
}
