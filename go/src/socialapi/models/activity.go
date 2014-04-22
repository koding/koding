package models

import (
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"time"
)

// Since we are not storing follow/join activities in Postgresql
// we need a new table for storing these
type Activity struct {
	Id           int64     `json:"id"`
	TargetId     int64     `json:"targetId" sql:"NOT NULL"`
	ActorId      int64     `json:"actorId" sql:"NOT NULL"`
	TypeConstant string    `json:"typeConstant" sql:"NOT NULL;TYPE:VARCHAR(100)"`
	UpdatedAt    time.Time `json:updatedAt`
}

func (a *Activity) GetId() int64 {
	return a.Id
}

func NewActivity() *Activity {
	return &Activity{}
}

func (a Activity) TableName() string {
	return "api.activity"
}

func (a *Activity) Create() error {
	s := map[string]interface{}{
		"target_id":     a.TargetId,
		"actor_id":      a.ActorId,
		"type_constant": a.TypeConstant,
	}

	q := bongo.NewQS(s)
	if err := a.One(q); err != nil {
		if err != gorm.RecordNotFound {
			return err
		}

		return bongo.B.Create(a)
	}

	return bongo.B.Update(a)
}

// TODO here it is a bit strange to just use updatedAt
func (a *Activity) BeforeCreate() {
	a.UpdatedAt = time.Now()
}

func (a *Activity) BeforeUpdate() {
	a.UpdatedAt = time.Now()
}

func (a *Activity) FetchActorIds() ([]int64, error) {
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"target_id":     a.TargetId,
			"type_constant": a.TypeConstant,
		},
		Sort: map[string]string{
			"updated_at": "desc",
		},
		Pluck: "actor_id",
	}
	var actorIds []int64

	if err := bongo.B.Some(a, &actorIds, q); err != nil {
		return nil, err
	}

	return actorIds, nil
}

func (a *Activity) Fetch() error {
	return bongo.B.Fetch(a)
}

func (a *Activity) One(q *bongo.Query) error {
	return bongo.B.One(a, a, q)
}
