package helpers

import (
	"errors"
	"net/http"
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

func NewBadRequestResponse() (int, http.Header, interface{}, error) {
	return http.StatusBadRequest, nil, nil, errors.New("Request is not valid")
}

func NewOKResponse(res interface{}) (int, http.Header, interface{}, error) {
	return http.StatusOK, nil, res, nil
}

func NewNotFoundResponse() (int, http.Header, interface{}, error) {
	return http.StatusNotFound, nil, nil, errors.New("Data not found")
}

func NewDeletedResponse() (int, http.Header, interface{}, error) {
	return http.StatusAccepted, nil, nil, nil
}
