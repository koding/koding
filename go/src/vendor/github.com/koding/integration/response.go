package integration

import "errors"

var ErrValidationError = errors.New("validation errors occurred")

type SuccessResponse struct {
	Data   interface{} `json:"data,omitempty"`
	Status bool        `json:"status"`
}

func NewSuccessResponse(data interface{}) *SuccessResponse {
	return &SuccessResponse{
		Status: true,
		Data:   data,
	}
}
