package models

import (
	"time"

	"github.com/koding/bongo"
)

// NewPresenceDaily create new PresenceDaily item
func NewPresenceDaily() *PresenceDaily {
	return &PresenceDaily{
		CreatedAt: time.Now().UTC(),
	}
}

// GetId returns the id
func (a PresenceDaily) GetId() int64 {
	return a.Id
}

// BongoName returns the unique name for the bongo operations
func (a PresenceDaily) BongoName() string {
	return "presence.daily"
}

// One fetches the item from db
func (a *PresenceDaily) One(q *bongo.Query) error {
	return bongo.B.One(a, a, q)
}

// Delete deletes the item from db
func (a *PresenceDaily) Delete() error {
	return bongo.B.Delete(a)
}

// Create inserts into db
func (a *PresenceDaily) Create() error {
	return bongo.B.Create(a)
}

// Some fetches items from db
func (a *PresenceDaily) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(a, data, q)
}

type countRes struct {
	Count int
}

// CountDistinctByGroupName counts distinct account ids
func (a *PresenceDaily) CountDistinctByGroupName(groupName string) (int, error) {
	res := &countRes{}
	return res.Count, bongo.B.DB.
		Table(a.BongoName()).
		Model(&PresenceDaily{}).
		Where("group_name = ? and is_processed = false", groupName).
		Select("count(distinct account_id)").
		Scan(res).Error
}

// ProcessByGroupName deletes items by their group's name from db
func (a *PresenceDaily) ProcessByGroupName(groupName string) error {
	// i have tried to use it ORM way but gorm has bugs that does not update multiple values at once
	sql := "UPDATE " + a.BongoName() + " SET is_processed=true WHERE group_name = ? and is_processed = false"
	return bongo.B.DB.Exec(sql, groupName).Error
}
