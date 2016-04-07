// Package models holds generated struct for FacebookProfile.
package models

import "github.com/cihangir/govalidator"

// Holds Facebook Profiles
type FacebookProfile struct {
	// The unique identifier for a Facebook Profile
	ID string `json:"id"`
	// First name for the Profile
	FirstName string `json:"firstName,omitempty"`
	// Middle name for the Profile. Optional
	MiddleName string `json:"middleName,omitempty"`
	// Last name for the Profile
	LastName string `json:"lastName,omitempty"`
	// Picture URL for the Profile
	PictureURL string `json:"pictureUrl,omitempty"`
}

// NewFacebookProfile creates a new FacebookProfile struct with default values
func NewFacebookProfile() *FacebookProfile {
	return &FacebookProfile{}
}

// Validate validates the FacebookProfile struct
func (f *FacebookProfile) Validate() error {
	return govalidator.NewMulti(govalidator.MinLength(f.FirstName, 1)).Validate()
}
