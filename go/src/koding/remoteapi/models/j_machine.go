package models

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	strfmt "github.com/go-openapi/strfmt"
	"github.com/go-openapi/swag"

	"github.com/go-openapi/errors"
	"github.com/go-openapi/validate"
)

// JMachine j machine
// swagger:model JMachine
type JMachine struct {

	// assignee
	Assignee *JMachineAssignee `json:"assignee,omitempty"`

	// created at
	CreatedAt strfmt.Date `json:"createdAt,omitempty"`

	// credential
	Credential string `json:"credential,omitempty"`

	// domain
	Domain string `json:"domain,omitempty"`

	// generated from
	GeneratedFrom *JMachineGeneratedFrom `json:"generatedFrom,omitempty"`

	// groups
	Groups []interface{} `json:"groups"`

	// ip address
	IPAddress string `json:"ipAddress,omitempty"`

	// label
	Label string `json:"label,omitempty"`

	// meta
	Meta interface{} `json:"meta,omitempty"`

	// provider
	// Required: true
	Provider *string `json:"provider"`

	// provisioners
	Provisioners []string `json:"provisioners"`

	// query string
	QueryString string `json:"queryString,omitempty"`

	// slug
	Slug string `json:"slug,omitempty"`

	// status
	Status *JMachineStatus `json:"status,omitempty"`

	// uid
	// Required: true
	UID *string `json:"uid"`

	// users
	Users []interface{} `json:"users"`
}

// Validate validates this j machine
func (m *JMachine) Validate(formats strfmt.Registry) error {
	var res []error

	if err := m.validateAssignee(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateGeneratedFrom(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateGroups(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateProvider(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateProvisioners(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateStatus(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateUID(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if err := m.validateUsers(formats); err != nil {
		// prop
		res = append(res, err)
	}

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}

func (m *JMachine) validateAssignee(formats strfmt.Registry) error {

	if swag.IsZero(m.Assignee) { // not required
		return nil
	}

	if m.Assignee != nil {

		if err := m.Assignee.Validate(formats); err != nil {
			return err
		}
	}

	return nil
}

func (m *JMachine) validateGeneratedFrom(formats strfmt.Registry) error {

	if swag.IsZero(m.GeneratedFrom) { // not required
		return nil
	}

	if m.GeneratedFrom != nil {

		if err := m.GeneratedFrom.Validate(formats); err != nil {
			return err
		}
	}

	return nil
}

func (m *JMachine) validateGroups(formats strfmt.Registry) error {

	if swag.IsZero(m.Groups) { // not required
		return nil
	}

	return nil
}

func (m *JMachine) validateProvider(formats strfmt.Registry) error {

	if err := validate.Required("provider", "body", m.Provider); err != nil {
		return err
	}

	return nil
}

func (m *JMachine) validateProvisioners(formats strfmt.Registry) error {

	if swag.IsZero(m.Provisioners) { // not required
		return nil
	}

	return nil
}

func (m *JMachine) validateStatus(formats strfmt.Registry) error {

	if swag.IsZero(m.Status) { // not required
		return nil
	}

	if m.Status != nil {

		if err := m.Status.Validate(formats); err != nil {
			return err
		}
	}

	return nil
}

func (m *JMachine) validateUID(formats strfmt.Registry) error {

	if err := validate.Required("uid", "body", m.UID); err != nil {
		return err
	}

	return nil
}

func (m *JMachine) validateUsers(formats strfmt.Registry) error {

	if swag.IsZero(m.Users) { // not required
		return nil
	}

	return nil
}

// JMachineAssignee j machine assignee
// swagger:model JMachineAssignee
type JMachineAssignee struct {

	// assigned at
	AssignedAt strfmt.Date `json:"assignedAt,omitempty"`

	// in progress
	InProgress bool `json:"inProgress,omitempty"`
}

// Validate validates this j machine assignee
func (m *JMachineAssignee) Validate(formats strfmt.Registry) error {
	var res []error

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}

// JMachineGeneratedFrom j machine generated from
// swagger:model JMachineGeneratedFrom
type JMachineGeneratedFrom struct {

	// revision
	Revision string `json:"revision,omitempty"`

	// template Id
	TemplateID string `json:"templateId,omitempty"`
}

// Validate validates this j machine generated from
func (m *JMachineGeneratedFrom) Validate(formats strfmt.Registry) error {
	var res []error

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}

// JMachineStatus j machine status
// swagger:model JMachineStatus
type JMachineStatus struct {

	// modified at
	ModifiedAt strfmt.Date `json:"modifiedAt,omitempty"`

	// reason
	Reason string `json:"reason,omitempty"`

	// state
	State string `json:"state,omitempty"`
}

// Validate validates this j machine status
func (m *JMachineStatus) Validate(formats strfmt.Registry) error {
	var res []error

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}