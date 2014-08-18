package models

type EmailSettings struct {
	Username           string
	Password           string
	DefaultFromAddress string
	DefaultFromMail    string
	ForcedRecipient    string
}
