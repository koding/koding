package models

import (
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

	author.Nick = "malitest" + strconv.Itoa(rand.Intn(10e6))

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
