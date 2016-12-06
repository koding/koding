package models

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	strfmt "github.com/go-openapi/strfmt"
	"github.com/go-openapi/swag"

	"github.com/go-openapi/errors"
	"github.com/go-openapi/validate"
)

// JCredential j credential
// swagger:model JCredential
type JCredential struct {

	// access level
	AccessLevel string `json:"accessLevel,omitempty"`

	// fields
	Fields []string `json:"fields"`

	// identifier
	// Required: true
	Identifier *string `json:"identifier"`

	// meta
	Meta interface{} `json:"meta,omitempty"`

	// origin Id
	// Required: true
	OriginID *string `json:"originId"`

	// provider
	// Required: true
	Provider *string `json:"provider"`

	// title
	// Required: true
	Title *string `json:"title"`

	// verified
	Verified bool `json:"verified,omitempty"`
}

// Validate validates this j credential
func (m *JCredential) Validate(formats strfmt.Registry) error {
	var res []error

	if err := m.validateFields(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateIdentifier(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateOriginID(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateProvider(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateTitle(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}

func (m *JCredential) validateFields(formats strfmt.Registry) error {

	if swag.IsZero(m.Fields) { // not required
		return nil
	}

	return nil
}

func (m *JCredential) validateIdentifier(formats strfmt.Registry) error {

	if err := validate.Required("identifier", "body", m.Identifier); err != nil {
		return err
	}

	return nil
}

func (m *JCredential) validateOriginID(formats strfmt.Registry) error {

	if err := validate.Required("originId", "body", m.OriginID); err != nil {
		return err
	}

	return nil
}

func (m *JCredential) validateProvider(formats strfmt.Registry) error {

	if err := validate.Required("provider", "body", m.Provider); err != nil {
		return err
	}

	return nil
}

func (m *JCredential) validateTitle(formats strfmt.Registry) error {

	if err := validate.Required("title", "body", m.Title); err != nil {
		return err
	}

	return nil
}