// Generated struct for MarkAsRequest.
package models

import "github.com/cihangir/govalidator"

type MarkAsRequest struct {
	// The unique identifier for a Account's Profile
	ID           int64  `json:"id,omitempty,string"`
	TypeConstant string `json:"typeConstant,omitempty"`
}

// NewMarkAsRequest creates a new MarkAsRequest struct with default values
func NewMarkAsRequest() *MarkAsRequest {
	return &MarkAsRequest{}
}

// Validate validates the MarkAsRequest struct
func (m *MarkAsRequest) Validate() error {
	return govalidator.NewMulti(govalidator.Min(float64(m.ID), 1.000000)).Validate()
}
