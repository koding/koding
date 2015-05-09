package models

import (
	kodingmodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"strconv"
	"time"

	"github.com/koding/bongo"
	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func CreateChannelWithParticipants() (*Channel, []*Account) {
	account1 := CreateAccountWithTest()
	account2 := CreateAccountWithTest()
	account3 := CreateAccountWithTest()
	accounts := []*Account{account1, account2, account3}

	channel := CreateChannelWithTest(account1.Id)
	AddParticipants(channel.Id, account1.Id, account2.Id, account3.Id)

	return channel, accounts
}

func CreateChannelWithTest(accountId int64) *Channel {
	// create and account instance
	channel := NewChannel()
	channel.CreatorId = accountId

	err := channel.Create()
	So(err, ShouldBeNil)

	return channel
}

// CreateTypedChannelWithTest creates a channel specific to a group with the
// given type constant
func CreateTypedChannelWithTest(accountId int64, typeConstant string) *Channel {
	// create and account instance
	channel := NewChannel()
	channel.Name = RandomName()
	// there is a check for group channels for unsuring that there will be only
	// one group channel at a time, override that
	channel.GroupName = RandomName()
	channel.TypeConstant = typeConstant
	channel.CreatorId = accountId

	err := channel.Create()
	So(err, ShouldBeNil)

	return channel
}

func CreateTypedGroupedChannelWithTest(accountId int64, typeConstant, groupName string) *Channel {
	// create and account instance
	channel := NewChannel()
	channel.Name = RandomName()
	// there is a check for group channels for unsuring that there will be only
	// one group channel at a time, override that
	channel.GroupName = groupName
	channel.TypeConstant = typeConstant
	channel.CreatorId = accountId

	err := channel.Create()
	So(err, ShouldBeNil)

	return channel
}

func CreateTypedPublicChannelWithTest(accountId int64, typeConstant string) *Channel {
	// create and account instance
	channel := NewChannel()
	channel.Name = RandomName()
	// there is a check for group channels for unsuring that there will be only
	// one group channel at a time, override that
	channel.GroupName = RandomName()
	channel.TypeConstant = typeConstant
	channel.CreatorId = accountId
	channel.PrivacyConstant = Channel_PRIVACY_PUBLIC

	err := channel.Create()
	So(err, ShouldBeNil)

	return channel
}

func CreateMessage(channelId, accountId int64, typeConstant string) *ChannelMessage {
	return CreateMessageWithBody(channelId, accountId, typeConstant, "testing message")
}

func CreateMessageWithBody(channelId, accountId int64, typeConstant, body string) *ChannelMessage {
	cm := NewChannelMessage()

	cm.AccountId = accountId
	// set channel id
	cm.InitialChannelId = channelId
	cm.TypeConstant = typeConstant
	// set body
	cm.Body = body

	err := cm.Create()
	So(err, ShouldBeNil)

	cml := NewChannelMessageList()
	cml.MessageId = cm.Id
	cml.ChannelId = channelId
	So(cml.Create(), ShouldBeNil)

	return cm
}

func CreateTrollMessage(channelId, accountId int64, typeConstant string) *ChannelMessage {
	cm := NewChannelMessage()

	cm.AccountId = accountId
	// set channel id
	cm.InitialChannelId = channelId
	cm.TypeConstant = typeConstant
	// set body
	cm.Body = "testing message"
	cm.MetaBits = Troll

	err := cm.Create()
	So(err, ShouldBeNil)

	return cm
}

func AddParticipants(channelId int64, accountIds ...int64) {

	for _, accountId := range accountIds {
		participant := NewChannelParticipant()
		participant.ChannelId = channelId
		participant.AccountId = accountId

		err := participant.Create()
		So(err, ShouldBeNil)
	}
}

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

func CreateAccountWithTest() *Account {
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

func FetchOrCreateSession(nick, groupName string) (*kodingmodels.Session, error) {
	session, err := modelhelper.GetOneSessionForAccount(nick, groupName)
	if err == nil {
		return session, nil
	}

	return modelhelper.CreateSessionForAccount(nick, groupName)
}

func CreateAccountInBothDbs() (*Account, error) {
	return CreateAccountInBothDbsWithNick(bson.NewObjectId().Hex())
}

func CreateAccountInBothDbsWithNick(nick string) (*Account, error) {
	accId := bson.NewObjectId()
	accHex := nick

	oldAcc, err := modelhelper.GetAccount(nick)
	if err == mgo.ErrNotFound {

		oldAcc = &kodingmodels.Account{
			Id: accId,
			Profile: struct {
				Nickname  string `bson:"nickname" json:"nickname"`
				FirstName string `bson:"firstName" json:"firstName"`
				LastName  string `bson:"lastName" json:"lastName"`
				Hash      string `bson:"hash" json:"hash"`
			}{
				Nickname: nick,
			},
		}

		err := modelhelper.CreateAccount(oldAcc)
		if err != nil {
			return nil, err
		}
	}

	oldUser, err := modelhelper.GetUser(nick)
	if err == mgo.ErrNotFound {
		oldUser = &kodingmodels.User{
			ObjectId:       bson.NewObjectId(),
			Password:       accHex,
			Salt:           accHex,
			Name:           nick,
			Email:          accHex + "@koding.com",
			EmailFrequency: kodingmodels.EmailFrequency{},
		}

		err = modelhelper.CreateUser(oldUser)
		if err != nil {
			return nil, err
		}
	}

	a := NewAccount()
	a.Nick = nick
	a.OldId = accId.Hex()

	if err := a.ByNick(nick); err == bongo.RecordNotFound {
		if err := a.Create(); err != nil {
			return nil, err
		}
	}

	if oldAcc.SocialApiId != strconv.FormatInt(a.Id, 10) {
		s := modelhelper.Selector{"_id": accId}
		o := modelhelper.Selector{"$set": modelhelper.Selector{
			"socialApiId": strconv.FormatInt(a.Id, 10),
		}}

		if err := modelhelper.UpdateAccount(s, o); err != nil {
			return nil, err
		}
	}

	return a, nil
}

func AddInteractionWithTest(iType string, messageId int64, accountId int64) (*Interaction, error) {
	cm := NewInteraction()
	cm.AccountId = accountId
	cm.MessageId = messageId
	cm.TypeConstant = iType
	So(cm.Create(), ShouldBeNil)

	return cm, nil
}

func CreateChannelLinkWithTest(acc1, acc2 int64) *ChannelLink {
	// root
	root := NewChannel()
	root.TypeConstant = Channel_TYPE_TOPIC
	root.CreatorId = acc1
	So(root.Create(), ShouldBeNil)

	// leaf
	leaf := NewChannel()
	leaf.TypeConstant = Channel_TYPE_TOPIC
	leaf.GroupName = root.GroupName // group names should be same
	leaf.CreatorId = acc2
	So(leaf.Create(), ShouldBeNil)

	cl := &ChannelLink{
		RootId: root.Id,
		LeafId: leaf.Id,
	}

	So(cl.Create(), ShouldBeNil)
	return cl
}
