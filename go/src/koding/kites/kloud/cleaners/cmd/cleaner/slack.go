package main

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
)

type Hook struct {
	URL      string `json:"webhook_url"`
	Channel  string `json:"channel,omitempty"`
	Username string `json:"username,omitempty"`
}

type Fields struct {
	Title string `json:"title"`
	Value string `json:"value"`
	Short bool   `json:"short"`
}

type Attachment struct {
	Fallback string   `json:"fallback,omitempty"`
	PreText  string   `json:"pretext,omitempty"`
	Text     string   `json:"text,omitempty"`
	Color    string   `json:"color,omitempty"`
	Fields   []Fields `json:"fields"`
	MrkdwnIn []string `json:"mrkdwn_in,omitempty"`
}

type Message struct {
	Channel     string       `json:"channel,omitempty"`
	Username    string       `json:"username,omitempty"`
	Text        string       `json:"text"`
	IconEmoji   string       `json:"icon_emoji,omitempty"`
	Attachments []Attachment `json:"attachments,omitempty"`
}

func (h Hook) Post(m Message) error {
	encoded, err := m.Encode()
	if err != nil {
		return err
	}

	resp, err := http.PostForm(h.URL, url.Values{"payload": {encoded}})
	if err != nil {
		return err
	}

	if resp.StatusCode != http.StatusOK {
		return errors.New("not OK")
	}

	return nil
}

func (m Message) Encode() (string, error) {
	b, err := json.Marshal(m)
	if err != nil {
		return "", err
	}

	return string(b), nil
}
