package models

import (
	"errors"

	"github.com/dgrijalva/jwt-go"
)

// type Message struct {
// 	Name string
// 	Body string 
// 	Time int64
// }

type Mail struct {
	FromName    string
	From        string
	MailboxHash string
	TextBody    string
	StrippedTextReply string
}

type ValidRequestFromMail struct {
	AccountId int64
	Email     string
	TargetId  int64
	Body      string
}

// errors
var(
	ErrNotValid = errors.New("no valid content")
	ErrAccountIsNotFound = errors.New("Account is not found")
	ErrFromFieldIsNotSet = errors.New("From field is not set")
	ErrTextBodyIsNotSet = errors.New("TextBody is not set")
)

func (m *Mail) GetFrom() string{
	return m.From
}

func (m *Mail) GetMailboxHash() string{
	return m.MailboxHash
}

func (m *Mail) GetTextBody() string{
	return m.TextBody
}

func (m *Mail) GetStrippedTextReply() string{
	return m.StrippedTextReply
}

// IsAccountExist controls the given mail adress as a parameter
// in the db, returns true if mail is exist in db, otherwise returns false
func isAccountExist(mail string) bool {
	// to do..
	// go to DB and controls the given mail adress as parameter
	// if mail adress is exist in db return something...
}

// GetAccount gets the account which sent the message 
func (m *Mail) GetAccount() *Account{
	
}

// AddMessageToRelatedChannel adds the taken message to the related channel
func AddMessageToRelatedChannel() {
	// to Do...
}


func (m *Mail) Validate() error {
	if m.GetFrom() == "" {
		return ErrFromFieldIsNotSet
	}

	if m.GetTextBody() == "" {
		return ErrTextBodyIsNotSet
	}

	// to Do..
	// account will be checked here via db
	if isAccountExist() {
		return ErrAccountIsNotFound
	}



	return nil
}

func (m *Mail) Parse(token *jwt.Token) (*ValidRequestFromMail, error) {
	return &ValidRequestFromMail{
		AccountId: 1,
		Email:     m.From,
		TargetId:  2131231,
		Body:      m.TextBody,
	}, nil
}

func (m *ValidRequestFromMail) Persist() error {
	// todo save data to db
	return nil
}
