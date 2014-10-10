package models

import (
	kodingmodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"strconv"
	"time"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

func createAccount() (*Account, error) {
	// create and account instance
	author := NewAccount()

	// create a fake mongo id
	oldId := bson.NewObjectId()
	// assign it to our test user
	author.OldId = oldId.Hex()

	// seed the random data generator
	rand.Seed(time.Now().UnixNano())

	author.Nick = "malitest" + strconv.Itoa(rand.Intn(10e9))

	if err := author.Create(); err != nil {
		return nil, err
	}

	return author, nil
}

func createAccountWithTest() *Account {
	account, err := createAccount()
	So(err, ShouldBeNil)
	So(account, ShouldNotBeNil)
	So(account.Id, ShouldNotEqual, 0)
	return account
}

func createChannel(accountId int64) (*Channel, error) {
	// create and account instance
	channel := NewChannel()
	channel.CreatorId = accountId

	if err := channel.Create(); err != nil {
		return nil, err
	}

	return channel, nil
}

func createMessageWithTest() *ChannelMessage {
	cm := NewChannelMessage()

	// init account
	account, err := createAccount()
	So(err, ShouldBeNil)
	So(account, ShouldNotBeNil)
	So(account.Id, ShouldNotEqual, 0)
	// init channel
	channel, err := createChannel(account.Id)
	So(err, ShouldBeNil)
	So(channel, ShouldNotBeNil)

	// set account id
	cm.AccountId = account.Id
	// set channel id
	cm.InitialChannelId = channel.Id
	// set body
	cm.Body = "5five"
	return cm
}

func FetchOrCreateSession(nick string) (*kodingmodels.Session, error) {
	session, err := modelhelper.GetOneSessionForAccount(nick)
	if err == nil {
		return session, nil
	}

	return modelhelper.CreateSessionForAccount(nick)
}

func CreateAccountInBothDbs() (*Account, error) {
	return CreateAccountInBothDbsWithNick(bson.NewObjectId().Hex())
}

func CreateAccountInBothDbsWithNick(nick string) (*Account, error) {
	accId := bson.NewObjectId()
	accHex := nick

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

	a := NewAccount()
	a.Nick = accHex
	a.OldId = accHex
	if err := a.Create(); err != nil {
		return nil, err
	}

	return a, nil
}
