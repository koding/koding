package helpers

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/helper"
	"strconv"

	"github.com/jinzhu/gorm"
)

// type ApiResponse struct {
// 	Status   int
// 	Header   http.Header
// 	Response interface{}
// 	Error    error
// }

// type ApiRequest struct {
// 	URL     *url.URL
// 	Header  http.Header
// 	Request interface{}
// }

// func NewResponse() *ApiResponse {
// 	return &ApiResponse{
// 		Status:   http.StatusOK,
// 		Header:   nil,
// 		Response: nil,
// 		Error:    nil,
// 	}
// }
func NewBadRequestResponse(err error) (int, http.Header, interface{}, error) {
	if err == nil {
		err = errors.New("Request is not valid")
	}

	helper.MustGetLogger().Error("Bad Request: %s", err)

	return http.StatusBadRequest, nil, nil, BadRequest{err}
}

func HandleResultAndError(res interface{}, err error) (int, http.Header, interface{}, error) {
	if err != nil {
		if err == gorm.RecordNotFound {
			return NewNotFoundResponse()
		}
		return NewBadRequestResponse(err)
	}
	return NewOKResponse(res)
}

func NewOKResponse(res interface{}) (int, http.Header, interface{}, error) {
	return http.StatusOK, nil, res, nil
}

func NewNotFoundResponse() (int, http.Header, interface{}, error) {
	return http.StatusNotFound, nil, nil, NotFoundError{errors.New("Data not found")}
}

func NewDeletedResponse() (int, http.Header, interface{}, error) {
	return http.StatusAccepted, nil, nil, nil
}

func NewDefaultOKResponse() (int, http.Header, interface{}, error) {
	res := map[string]interface{}{
		"status": true,
	}

	return http.StatusOK, nil, res, nil
}

func GetId(u *url.URL) (int64, error) {
	return strconv.ParseInt(u.Query().Get("id"), 10, 64)
}

func GetURIInt64(u *url.URL, queryParam string) (int64, error) {
	return strconv.ParseInt(u.Query().Get(queryParam), 10, 64)
}

func GetQuery(u *url.URL) *models.Query {
	return models.NewQuery().MapURL(u).SetDefaults()
}

type BadRequest struct {
	error
}

func (err BadRequest) Name() string { return "koding.BadRequest" }

func (err BadRequest) StatusCode() int { return http.StatusBadRequest }

type NotFoundError struct {
	error
}

func (err NotFoundError) Name() string { return "koding.NotFoundError" }

func (err NotFoundError) StatusCode() int { return http.StatusNotFound }
