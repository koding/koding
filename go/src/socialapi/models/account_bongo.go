package models

import (
	"errors"

	"github.com/koding/bongo"
	uuid "github.com/satori/go.uuid"
)

func NewAccount() *Account {
	return &Account{}
}

func (a Account) GetId() int64 {
	return a.Id
}

func (a Account) BongoName() string {
	return "api.account"
}

func (a *Account) BeforeCreate() error {
	return a.createToken()
}

func (a *Account) BeforeUpdate() error {
	return a.createToken()
}

func (a *Account) createToken() error {
	if a.Token == "" {
		token := uuid.NewV4()
		a.Token = token.String()
	}

	return nil
}

func (a *Account) AfterUpdate() {
	SetAccountToCache(a)
	bongo.B.AfterUpdate(a)
}

func (a *Account) AfterCreate() {
	SetAccountToCache(a)
	bongo.B.AfterCreate(a)
}

func (a *Account) One(q *bongo.Query) error {
	return bongo.B.One(a, a, q)
}

func (a *Account) ById(id int64) error {
	return bongo.B.ById(a, id)
}

func (a *Account) ByToken(token string) error {
	if token == "" {
		return ErrIdIsNotSet
	}
	selector := map[string]interface{}{
		"token": token,
	}

	return a.One(bongo.NewQS(selector))
}

func (a *Account) Update() error {
	return bongo.B.Update(a)
}

func (a *Account) Create() error {
	if a.OldId == "" {
		return errors.New("old id is not set")
	}

	if a.Nick == "guestuser" {
		return ErrGuestsAreNotAllowed
	}

	return bongo.B.Create(a)
}

func (a *Account) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(a, data, q)
}

func (a *Account) Delete() error {
	return bongo.B.DB.Unscoped().Delete(a).Error
}

func (a *Account) FetchByIds(ids []int64) ([]Account, error) {
	var accounts []Account

	if len(ids) == 0 {
		return accounts, nil
	}

	if err := bongo.B.FetchByIds(a, &accounts, ids); err != nil {
		return nil, err
	}

	return accounts, nil
}
