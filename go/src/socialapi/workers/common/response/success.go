package response

type SuccessResponse struct {
	Data   interface{} `json:"data"`
	Error  error       `json:"error"`
	Status bool        `json:"status"`
}

func NewSuccessResponse(data interface{}) *SuccessResponse {
	return &SuccessResponse{
		Status: true,
		Data:   data,
	}
}
