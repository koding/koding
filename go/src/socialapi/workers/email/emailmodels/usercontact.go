package emailmodels

import (
	"errors"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	notificationmodels "socialapi/workers/notification/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
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

	LastLoginTimezoneOffset int
}

var emailConfig = map[string]string{
	notificationmodels.NotificationContent_TYPE_COMMENT: "comment",
	notificationmodels.NotificationContent_TYPE_LIKE:    "likeActivities",
	notificationmodels.NotificationContent_TYPE_MENTION: "mention",
	notificationmodels.NotificationContent_TYPE_PM:      "privateMessage",
}

// fetchUserContact gets user and account details with given account id
func FetchUserContactWithToken(accountId int64) (*UserContact, error) {

	uc, err := FetchUserContact(accountId)
	if err != nil {
		return nil, err
	}

	token, err := NewTokenGenerator().Generate()
	if err != nil {
		return nil, err
	}

	uc.Token = token

	return uc, nil
}

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

	return &UserContact{
		AccountId:               accountId,
		UserOldId:               user.ObjectId,
		Email:                   user.Email,
		FirstName:               account.Profile.FirstName,
		LastName:                account.Profile.LastName,
		Username:                account.Profile.Nickname,
		Hash:                    account.Profile.Hash,
		EmailSettings:           user.EmailFrequency,
		LastLoginTimezoneOffset: account.LastLoginTimezoneOffset,
	}, nil
}

func (uc *UserContact) GenerateToken(notificationType string) error {
	tg := &TokenGenerator{
		UserContact:      uc,
		NotificationType: emailConfig[notificationType],
	}

	return tg.CreateToken()
}
