package models

type EmailSettings struct {
	Username        string
	Password        string
	DefaultFromName string
	DefaultFromMail string
	ForcedRecipient string
}
