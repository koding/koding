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
	ErrServiceOverloaded = errors.New("service overloaded")
	ErrUnknown           = errors.New("unknown error")
	ErrContentNotFound   = errors.New("content not found")
	ErrInternalError     = errors.New("internal error")
)

type Fallback func(string) error

var FallbackFn Fallback

type ErrorResponse struct {
	Description string `json:"description"`
	Error       string `json:"error"`
}

type BotChannelResponse struct {
	Data   BotChannelData `json:"data"`
	Status bool           `json:"status"`
}

type BotChannelData struct {
	ChannelId int64    `json:"channelId,string"`
	Setting   Settings `json:"settings,omitempty"`
}

//////////// PushRequest //////////////

type PushRequest struct {
	Body       string             `json:"body"`
	ChannelId  int64              `json:"channelId,string"`
	GroupName  string             `json:"groupName"`
	Token      string             `json:"token"`
	FallbackFn Fallback           `json:"-"`
	Payload    map[string]*string `json:"payload"`
}

// NewPushRequest creates a new PushRequest instance with Fallback function
func NewPushRequest(body string) *PushRequest {
	return &PushRequest{
		FallbackFn: FallbackFn,
		Body:       body,
	}
}

func (pr *PushRequest) Buffered() (io.Reader, error) {
	body, err := json.Marshal(pr)
	if err != nil {
		return nil, err
	}

	return bytes.NewReader(body), nil
}

// Fallback stores the Push request arguments in a queue, when a
// fallback function is attached to push request
func (pr *PushRequest) Fallback(token, rootPath string) error {
	if pr.FallbackFn == nil {
		return nil
	}

	fr := &FallbackRequest{}
	fr.Body = pr
	fr.RootPath = rootPath
	fr.Token = token

	body, err := json.Marshal(fr)
	if err != nil {
		return err
	}

	return pr.FallbackFn(string(body))
}

func (pr *PushRequest) SetPayload(key string, value string) {
	if pr.Payload == nil {
		pr.Payload = make(map[string]*string)
	}
	pr.Payload[key] = &value
}

func FallbackHandler(message *string) error {
	if message == nil {
		return nil
	}

	fr := FallbackRequest{}
	err := json.Unmarshal([]byte(*message), &fr)
	if err != nil {
		return err
	}

	if err := fr.Push(); err != nil {
		return err
	}

	return nil
}

////////// FallbackRequest /////////////

type FallbackRequest struct {
	Token    string       `json:"token"`
	Body     *PushRequest `json:"body"`
	RootPath string       `json:"rootPath"`
}

func (fr *FallbackRequest) Push() error {
	return Push(fr.Token, fr.Body, fr.RootPath)
}

////////// ConfigureRequest ////////////

type ConfigureRequest struct {
	UserToken    string   `json:"userToken"`
	Settings     Settings `json:"settings"`
	OldSettings  Settings `json:"oldSettings"`
	ServiceToken string   `json:"serviceToken"`
}

type Settings map[string]*string

func (s Settings) Get(key string) *string {
	val, ok := s[key]
	if !ok {
		return nil
	}

	return val
}

func (s Settings) GetString(key string) string {
	val := s.Get(key)
	if val == nil {
		return ""
	}

	return *val
}

type ConfigureResponse map[string]interface{}

func MapConfigureRequest(req *http.Request, val interface{}) error {
	if err := json.NewDecoder(req.Body).Decode(val); err != nil {
		return err
	}

	return req.Body.Close()
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
	if resp.StatusCode == 500 {
		return ErrInternalError
	}

	if resp.StatusCode == 502 {
		return ErrServiceOverloaded
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

// GetSettings fetchs the events from integratin's DB.
// And extracts all events which allowed by user from data
func GetSettings(token, rootPath string) (Settings, error) {
	endpoint := fmt.Sprintf("%s/settings/%s", rootPath, token)

	resp, err := http.Get(endpoint)
	defer func() {
		if resp != nil {
			resp.Body.Close()
		}
	}()

	if resp.StatusCode != 200 {
		err := ParseError(resp)

		return nil, err
	}

	event := &BotChannelResponse{}

	if err = json.NewDecoder(resp.Body).Decode(event); err != nil {
		return nil, err
	}

	return event.Data.Setting, nil
}

func UnmarshalEvents(s Settings) ([]string, error) {
	val := s.GetString("events")
	if val == "" {
		return []string{}, nil
	}

	var events []string
	err := json.Unmarshal([]byte(val), &events)

	return events, err
}

// Push makes a request to push endpoint of webhook worker. When the worker is down
// or if it returns an Internal Server Error, message is pushed to the fallback
// queue
func Push(token string, pr *PushRequest, rootPath string) error {
	endpoint := fmt.Sprintf("%s/push/%s", rootPath, token)
	reader, err := pr.Buffered()
	if err != nil {
		return err
	}

	resp, err := http.Post(endpoint, "application/json", reader)
	defer func() {
		if resp != nil {
			resp.Body.Close()
		}
	}()

	if err != nil {
		// When webhook server is down, push request must be queued
		pr.Fallback(token, rootPath)
		return err
	}

	if resp.StatusCode != 200 {
		err := ParseError(resp)
		if err == ErrInternalError {
			pr.Fallback(token, rootPath)
		}

		return err
	}

	return nil
}
