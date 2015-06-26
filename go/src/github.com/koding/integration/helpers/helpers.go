package helpers

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
)

var (
	ErrBadGateway      = errors.New("bad gateway")
	ErrUnknown         = errors.New("unknown error")
	ErrContentNotFound = errors.New("content not found")
)

type ErrorResponse struct {
	Description string `json:"description"`
	Error       string `json:"error"`
}

type BotChannelResponse struct {
	Data   BotChannelData `json:"data"`
	Status bool           `json:"status"`
}

type BotChannelData struct {
	ChannelId int64 `json:"channelId,string"`
}

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

// fetchBotChannelId retrieves the user's bot channel id within the given
// group context
func FetchBotChannelId(username, token, rootPath string) (int64, error) {
	endpoint := fmt.Sprintf("%s/botchannel/%s/user/%s", rootPath, token, username)
	resp, err := http.Get(endpoint)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		var r BotChannelResponse
		err = json.NewDecoder(resp.Body).Decode(&r)

		return r.Data.ChannelId, err
	}

	return 0, ParseError(resp)
}

func ParseError(resp *http.Response) error {
	if resp.StatusCode == 502 {
		return ErrBadGateway
	}

	if resp.StatusCode == 404 {
		return ErrContentNotFound
	}

	if resp.StatusCode == 400 {
		var er ErrorResponse
		err := json.NewDecoder(resp.Body).Decode(&er)
		if err != nil {
			return err
		}

		return errors.New(er.Description)
	}

	return ErrUnknown
}

func Push(token string, pr *PushRequest, rootPath string) error {
	endpoint := fmt.Sprintf("%s/push/%s", rootPath, token)
	reader, err := pr.Buffered()
	if err != nil {
		return err
	}

	resp, err := http.Post(endpoint, "application/json", reader)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return ParseError(resp)
	}

	return nil
}
