package models

import (
	"errors"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type UserContact struct {
	AccountId     int64
	UserOldId     bson.ObjectId
	Email         string
	FirstName     string
	LastName      string
	Username      string
	Hash          string
	Token         string
	EmailSettings *mongomodels.EmailFrequency
}

// fetchUserContact gets user and account details with given account id
func FetchUserContact(accountId int64) (*UserContact, error) {
	a := models.NewAccount()
	if err := a.ById(accountId); err != nil {
		return nil, err
	}

	account, err := modelhelper.GetAccountById(a.OldId)
	if err != nil {
		if err == mgo.ErrNotFound {
			return nil, errors.New("old account not found")
		}

		return nil, err
	}

	user, err := modelhelper.GetUser(account.Profile.Nickname)
	if err != nil {
		if err == mgo.ErrNotFound {
			return nil, errors.New("user not found")
		}

		return nil, err
	}

	token, err := NewTokenGenerator().GenerateToken()
	if err != nil {
		return nil, err
	}

	return &UserContact{
		AccountId:     accountId,
		UserOldId:     user.ObjectId,
		Email:         user.Email,
		FirstName:     account.Profile.FirstName,
		LastName:      account.Profile.LastName,
		Username:      account.Profile.Nickname,
		Hash:          account.Profile.Hash,
		EmailSettings: &user.EmailFrequency,
		Token:         token,
	}, nil
}
