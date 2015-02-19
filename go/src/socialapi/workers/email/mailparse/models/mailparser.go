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
	// FromName is the name of the user who sent the message
	FromName string
	// From holds the mail address of user
	From string
	// OriginalRecipient holds the inbound mail
	// adress which user sent the message
	OriginalRecipient string
	// MailboxHash holds the data according to OriginalRecipient
	// As an example if Original Recipient is mehmetali+channel@inbound.koding.com
	// then MailboxHash would be "channel".
	MailboxHash string
	// TextBody is the body of the message
	TextBody string
	// StrippedTextReply is message body if the message is reply (not post)
	StrippedTextReply string
}

// errors
var (
	ErrNotValid          = errors.New("no valid content")
	ErrAccountIsNotFound = errors.New("Account is not found")
	ErrFromFieldIsNotSet = errors.New("From field is not set")
	ErrTextBodyIsNotSet  = errors.New("TextBody is not set")
	errInvalidMailPrefix = errors.New("invalid prefix")
	errLengthIsNotEnough = errors.New("Lenght is not enough")
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
		if len(s) < 1 {
			return errLengthIsNotEnough
		}
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
		if c.TypeConstant == socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE {
			cm.TypeConstant = socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE
		}
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
		if len(s) < 1 {
			return errLengthIsNotEnough
		}
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
		if cm.TypeConstant == socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE {
			reply.TypeConstant = socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE
		}
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

// JSON DATA EXAMPLE
// 	data := `{
//   "FromName": "Cihangir Savas",
//   "From": "cihangir@koding.com",
//   "FromFull": {
//     "Email": "cihangir@koding.com",
//     "Name": "Cihangir Savas",
//     "MailboxHash": ""
//   },
//   "To": "cihangir+c753ccab0f110add98f4edee21431ca7@inbound.koding.com",
//   "ToFull": [
//     {
//       "Email": "cihangir+c753ccab0f110add98f4edee21431ca7@inbound.koding.com",
//       "Name": "",
//       "MailboxHash": "c753ccab0f110add98f4edee21431ca7"
//     }
//   ],
//   "Cc": "",
//   "CcFull": [],
//   "Bcc": "",
//   "BccFull": [],
//   "Subject": "Re: cihangir+c753ccab0f110add98f4edee21431ca7 test",
//   "MessageID": "941469ab-694d-43bd-931d-15ad0da2d052",
//   "ReplyTo": "",
//   "MailboxHash": "c753ccab0f110add98f4edee21431ca7",
//   "Date": "Sun, 7 Sep 2014 01:42:17 -0700",
//   "TextBody": "testing mail parse.....\r\n",
//   "HtmlBody": "<div dir=\"ltr\"><font color=\"#333333\" face=\"Helvetica Neue, Arial, Helvetica, sans-serif\"><span style=\"font-size:14px;line-height:19.6000003814697px\">testing mail parse.....<\/span><\/font><\/div>\r\n",
//   "StrippedTextReply": "",
//   "Tag": "",
//   "Headers": [
//     {
//       "Name": "X-Spam-Checker-Version",
//       "Value": "SpamAssassin 3.3.1 (2010-03-16) on sc-ord-inbound1"
//     },
//     {
//       "Name": "X-Spam-Status",
//       "Value": "No"
//     },
//     {
//       "Name": "X-Spam-Score",
//       "Value": "-0.7"
//     },
//     {
//       "Name": "X-Spam-Tests",
//       "Value": "HTML_MESSAGE,RCVD_IN_DNSWL_LOW,SPF_PASS"
//     },
//     {
//       "Name": "Received-SPF",
//       "Value": "Pass (sender SPF authorized) identity=mailfrom; client-ip=209.85.216.52; helo=mail-qa0-f52.google.com; envelope-from=cihangir@koding.com; receiver=cihangir+c753ccab0f110add98f4edee21431ca7@inbound.koding.com"
//     },
//     {
//       "Name": "X-Google-DKIM-Signature",
//       "Value": "v=1; a=rsa-sha256; c=relaxed\/relaxed;        d=1e100.net; s=20130820;        h=x-gm-message-state:mime-version:date:message-id:subject:from:to         :content-type;        bh=8Je8F3I+Al30FHRlQlzrFs5oZQvPIQ2UrA0rIk5+Zm4=;        b=DkqIXBatAZTCALrw\/1bh6VWKhnsHoEXS6MzwbE\/KoOkmrVB5gOAQI\/39TUBZUJRRNX         l4uOo0kH9KxI2FEWwP\/n4ViOvxn2sY\/0ZWGPFRM4jhOm7OvFspA3VvZL8wpddxquwk+Z         RosWQ\/ixUb7BrpgoTR3DTnwt7PirYhbvA\/KOSSFSeIuVNjvo0RcSX0BJ8o+kXvyIq2Xd         5MF+jkQwwmhalfxAEiO1jSiLYp4moHznDCfPFxmceT7oSrJ+OuQL96\/UW3ljKK2n4hk8         aQpwBdO2PtUPh17Q6X4D2MgYY1y4\/6+EBuFxLgab65CEE5+Vo6vt7JIxcwZpZROAlFWG         qNZA=="
//     },
//     {
//       "Name": "X-Gm-Message-State",
//       "Value": "ALoCoQl6UC1K8o2LeFAsjSPHhRQA0uQkDQfK6Y0fFFQsJ8eXc0fszOxIwN7qmv0L3tIq5kX2vF54"
//     },
//     {
//       "Name": "MIME-Version",
//       "Value": "1.0"
//     },
//     {
//       "Name": "X-Received",
//       "Value": "by 10.140.92.97 with SMTP id a88mr12550710qge.85.1410079337953; Sun, 07 Sep 2014 01:42:17 -0700 (PDT)"
//     },
//     {
//       "Name": "X-Originating-IP",
//       "Value": "[2604:5500:1c:1fa:6d5e:b6c9:3ec9:4c5d]"
//     },
//     {
//       "Name": "Message-ID",
//       "Value": "<CAORUdqjqgvvHOxtk_isqQ49aToxMzOPUJ40Ga9o2Z7M0En=xEw@mail.gmail.com>"
//     }
//   ],
//   "Attachments": []
// }`
