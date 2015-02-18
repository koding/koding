package models

import (
	"errors"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"strconv"
	"strings"
)

type Mail struct {
	FromName          string
	From              string
	OriginalRecipient string
	MailboxHash       string
	TextBody          string
	StrippedTextReply string
}

// errors
var (
	ErrNotValid          = errors.New("no valid content")
	ErrAccountIsNotFound = errors.New("Account is not found")
	ErrFromFieldIsNotSet = errors.New("From field is not set")
	ErrTextBodyIsNotSet  = errors.New("TextBody is not set")
	errInvalidMailPrefix = errors.New("invalid prefix")
)

// GetAccount gets the account which sent the message
func GetAccount(mailAddress string) (*mongomodels.Account, error) {
	user, err := modelhelper.FetchUserByEmail(mailAddress)
	if err != nil {
		return nil, err
	}

	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		return nil, err
	}
	return account, nil
}

func (m *Mail) Validate() error {
	if m.From == "" {
		return ErrFromFieldIsNotSet
	}

	if m.TextBody == "" {
		return ErrTextBodyIsNotSet
	}

	return nil
}

// Examples of postmark inbound messages
// reply+messageid.1234@inbound.koding.com
// post+channelid.5678@inbound.koding.com
func (m *Mail) Persist() error {
	//acc := socialapimodels.NewAccount()
	acc, err := GetAccount(m.From)
	if err != nil {
		return errInvalidMailPrefix
	}

	accountId, err := acc.GetSocialApiId()
	if err != nil {
		return err
	}

	if strings.HasPrefix(m.OriginalRecipient, "post") {
		// Split method get the MailboxHash field
		// MailboxHash seems like "channelid.5678"
		s := strings.Split(m.MailboxHash, ".")
		// ParseInt get the 1. index (2.parameter) of "s" value
		// As explained above, we got 1. index that "5678" as string
		// and then, we convert string to int64
		cid, err := strconv.ParseInt(s[1], 10, 64)
		if err != nil {
			return err
		}

		channelId := cid
		c, err := socialapimodels.ChannelById(channelId)
		if err != nil {
			return err
		}

		cm := socialapimodels.NewChannelMessage()
		cm.Body = m.TextBody // set the body
		// todo set this type according to the the channel id
		cm.TypeConstant = socialapimodels.ChannelMessage_TYPE_POST
		cm.InitialChannelId = channelId
		cm.AccountId = accountId
		if err := cm.Create(); err != nil {
			return err
		}

		_, err = c.EnsureMessage(cm, true)
		if err != nil {
			return err
		}

		return nil
	}

	if strings.HasPrefix(m.OriginalRecipient, "reply") {
		s := strings.Split(m.MailboxHash, ".")
		mId, err := strconv.ParseInt(s[1], 10, 64)
		if err != nil {
			return err
		}
		messageId := mId
		cm, err := socialapimodels.ChannelMessageById(messageId)
		if err != nil {
			return err
		}

		// create reply
		reply := socialapimodels.NewChannelMessage()
		reply.Body = m.StrippedTextReply // set the body
		// todo set this type according to the the channel id
		reply.TypeConstant = socialapimodels.ChannelMessage_TYPE_REPLY
		reply.InitialChannelId = cm.InitialChannelId
		reply.AccountId = accountId
		if err := reply.Create(); err != nil {
			return err
		}

		if _, err = cm.AddReply(reply); err != nil {
			return err
		}

		return nil
	}

	return errInvalidMailPrefix

}
