package integration

import (
	"encoding/json"
	"errors"
	"net/http"
)

var ErrValidationError = errors.New("validation errors occurred")

type SuccessResponse struct {
	Data   interface{} `json:"data,omitempty"`
	Status bool        `json:"status"`
}

type BotChannelResponse struct {
	Data   BotChannelData `json:"data"`
	Status bool           `json:"status"`
}

type BotChannelData struct {
	ChannelId int64 `json:"channelId,string"`
}

type ErrorResponse struct {
	Description string `json:"description"`
	Error       string `json:"error"`
}

func NewSuccessResponse(data interface{}) *SuccessResponse {
	return &SuccessResponse{
		Status: true,
		Data:   data,
	}
}

func NewBadRequest(err error) (int, http.Header, interface{}, error) {
	if err == nil {
		err = errors.New("an error occurred")
	}

	return http.StatusBadRequest, nil, nil, err
}

func NewNotFound(err error) (int, http.Header, interface{}, error) {
	if err == nil {
		err = ErrContentNotFound
	}

	return http.StatusNotFound, nil, nil, ErrContentNotFound
}

func NewOK(res interface{}) (int, http.Header, interface{}, error) {
	return http.StatusOK, nil, NewSuccessResponse(res), nil
}

func parseError(resp *http.Response) error {

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
