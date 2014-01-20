package slack

import (
	"encoding/json"
	"fmt"
	"net/url"
)

type MessageService struct {
	C *Client
}

type MessagesResponse struct {
	Ok        int    `json:"ok"`
	Timestamp string `json:"timestamp"`
}

type Message struct {
	Channel  string `json:"channel"`
	Text     string `json:"text"`
	Username string `json:"username"`
}

func (m *MessageService) Post(message *Message) (*MessagesResponse, error) {
	var response *MessagesResponse

	var val = url.Values{}
	val.Set("channel", message.Channel)
	val.Add("text", message.Text)

	var url = fmt.Sprintf("api/chat.postMessage?%v", val.Encode())
	var body, err = m.C.Request("POST", url, message)
	if err != nil {
		return response, err
	}

	defer body.Close()

	err = json.NewDecoder(body).Decode(&response)
	if err != nil {
		return response, err
	}

	return response, nil
}

func NewMessageService(c *Client) *MessageService {
	return &MessageService{c}
}
