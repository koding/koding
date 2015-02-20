package rest

import (
	"socialapi/workers/email/mailparse/models"
)

func MailParse(m *models.Mail) (*models.Mail, error) {
	url := "/mail/parse"
	res, err := sendModel("POST", url, m)
	if err != nil {
		return nil, err
	}

	return res.(*models.Mail), nil
}
