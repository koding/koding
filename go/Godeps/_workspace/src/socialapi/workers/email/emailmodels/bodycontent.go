package emailmodels

import "socialapi/models"

type BodyContent struct {
	// Stores channel title
	Title string
	// MessageSummaries are in descending order
	MessageSummaries []*MessageSummary

	TimezoneOffset int

	IsNicknameShown bool
}

func NewBodyContent() *BodyContent {
	return &BodyContent{
		MessageSummaries: make([]*MessageSummary, 0),
	}
}

func (bc *BodyContent) AddMessages(messages []models.ChannelMessage) error {
	for _, message := range messages {
		nickname, err := bc.FetchMessageOwnerNickname(message.AccountId)
		if err != nil {
			return err
		}

		ms := NewMessageSummary(nickname, bc.TimezoneOffset, message.Body, message.CreatedAt)
		bc.MessageSummaries = append(bc.MessageSummaries, ms)
	}

	return nil
}

func (bc *BodyContent) Render() (string, error) {
	body := ""
	for _, ms := range bc.MessageSummaries {
		content, err := ms.Render()
		if err != nil {
			return "", err
		}
		body += content
	}

	return body, nil
}

func (bc *BodyContent) FetchMessageOwnerNickname(accountId int64) (string, error) {
	if !bc.IsNicknameShown {
		return "", nil
	}

	account, err := models.Cache.Account.ById(accountId)
	if err != nil {
		return "", err
	}

	return account.Nick, nil
}
