package integration

import (
	"bytes"
	"encoding/json"
	"io"
)

type PushRequest struct {
	Body      string `json:"body"`
	ChannelId int64  `json:"channelId,string"`
	GroupName string `json:"groupName"`
	Token     string `json:"token"`
}

func (pr *PushRequest) Buffered() (io.Reader, error) {
	body, err := json.Marshal(pr)
	if err != nil {
		return nil, err
	}

	return bytes.NewReader(body), nil
}
