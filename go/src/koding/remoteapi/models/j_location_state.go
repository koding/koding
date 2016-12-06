package models

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	strfmt "github.com/go-openapi/strfmt"

	"github.com/go-openapi/errors"
)

// JLocationState j location state
// swagger:model JLocationState
type JLocationState struct {

	// country code
	CountryCode string `json:"countryCode,omitempty"`

	// state
	State string `json:"state,omitempty"`

	// state code
	StateCode string `json:"stateCode,omitempty"`
}

// Validate validates this j location state
func (m *JLocationState) Validate(formats strfmt.Registry) error {
	var res []error

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}