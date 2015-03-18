package models

import (
	"time"

	"github.com/koding/bongo"
)

const PermissionBongoName = "api.permission"

func (p Permission) GetId() int64 {
	return p.Id
}

func (p Permission) BongoName() string {
	return PermissionBongoName
}

func (p Permission) TableName() string {
	return p.BongoName()
}

func (p *Permission) AfterCreate() {
	bongo.B.AfterCreate(p)
}

func (p *Permission) AfterUpdate() {
	bongo.B.AfterUpdate(p)
}

func (p Permission) AfterDelete() {
	bongo.B.AfterDelete(p)
}

func (p *Permission) BeforeCreate() {
	p.CreatedAt = time.Now().UTC()
	p.UpdatedAt = time.Now().UTC()
}

func (p *Permission) BeforeUpdate() {
	p.UpdatedAt = time.Now()
}

func (p *Permission) Create() error {
	return bongo.B.Create(p)
}

func (p *Permission) Update() error {
	return bongo.B.Update(p)
}

func (p *Permission) Delete() error {
	return bongo.B.Delete(p)
}

func (p *Permission) ById(id int64) error {
	return bongo.B.ById(p, id)
}

func (p *Permission) One(q *bongo.Query) error {
	return bongo.B.One(p, p, q)
}

func (p *Permission) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(p, data, q)
}

func (p *Permission) FetchByIds(ids []int64) ([]Permission, error) {
	var Permissions []Permission

	if len(ids) == 0 {
		return Permissions, nil
	}

	if err := bongo.B.FetchByIds(p, &Permissions, ids); err != nil {
		return nil, err
	}

	return Permissions, nil
}

func (p *Permission) CountWithQuery(q *bongo.Query) (int, error) {
	return bongo.B.CountWithQuery(p, q)
}
