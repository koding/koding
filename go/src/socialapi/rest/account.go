package rest

import (
	kodingmodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"labix.org/v2/mgo/bson"
	"socialapi/models"
)

func CreateAccount(a *models.Account) (*models.Account, error) {
	a.Nick = a.OldId
	acc, err := sendModel("POST", "/account", a)
	if err != nil {
		return nil, err
	}

	return acc.(*models.Account), nil
}

func CreateAccountInBothDbs() (*models.Account, error) {
	accId := bson.NewObjectId()
	accHex := accId.Hex()

	oldAcc := &kodingmodels.Account{
		Id: accId,
		Profile: struct {
			Nickname  string `bson:"nickname"`
			FirstName string `bson:"firstName"`
			LastName  string `bson:"lastName"`
			Hash      string `bson:"hash"`
		}{
			Nickname: accHex,
		},
	}

	err := modelhelper.CreateAccount(oldAcc)
	if err != nil {
		return nil, err
	}

	oldUser := &kodingmodels.User{
		ObjectId:       bson.NewObjectId(),
		Password:       accHex,
		Salt:           accHex,
		Name:           accHex,
		Email:          accHex,
		EmailFrequency: kodingmodels.EmailFrequency{},
	}

	err = modelhelper.CreateUser(oldUser)
	if err != nil {
		return nil, err
	}

	a := models.NewAccount()
	a.Nick = accHex
	a.OldId = accHex

	acc, err := sendModel("POST", "/account", a)

	if err != nil {
		return nil, err
	}

	return acc.(*models.Account), nil
}
