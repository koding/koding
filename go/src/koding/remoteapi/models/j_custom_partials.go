package models

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	strfmt "github.com/go-openapi/strfmt"

	"github.com/go-openapi/errors"
)

// JCustomPartials j custom partials
// swagger:model JCustomPartials
type JCustomPartials struct {

	// id
	ID string `json:"_id,omitempty"`

	// created at
	CreatedAt strfmt.Date `json:"createdAt,omitempty"`

	// is active
	IsActive bool `json:"isActive,omitempty"`

	// is preview
	IsPreview bool `json:"isPreview,omitempty"`

	// name
	Name string `json:"name,omitempty"`

	// partial
	Partial interface{} `json:"partial,omitempty"`

	// partial type
	PartialType string `json:"partialType,omitempty"`

	// preview instance
	PreviewInstance string `json:"previewInstance,omitempty"`

	// published at
	PublishedAt strfmt.Date `json:"publishedAt,omitempty"`

	// view instance
	ViewInstance string `json:"viewInstance,omitempty"`
}

// Validate validates this j custom partials
func (m *JCustomPartials) Validate(formats strfmt.Registry) error {
	var res []error

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}
