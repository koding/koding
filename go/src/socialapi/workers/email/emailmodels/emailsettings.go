package emailmodels

import "socialapi/config"

type EmailSettings struct {
	Username        string
	Password        string
	DefaultFromName string
	DefaultFromMail string
	ForcedRecipient string
}

func NewEmailSettings(conf *config.Config) *EmailSettings {
	return &EmailSettings{
		Username:        conf.Email.Username,
		Password:        conf.Email.Password,
		DefaultFromMail: conf.Email.DefaultFromMail,
		DefaultFromName: conf.Email.DefaultFromName,
		ForcedRecipient: conf.Email.ForcedRecipient,
	}
}
