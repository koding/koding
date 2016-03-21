// Generated struct for FacebookFriends.
package models

import "github.com/cihangir/govalidator"

// Holds Facebook Friendship Status
type FacebookFriends struct {
	// The source unique identifier for a Facebook Profile, smaller one will be
	// source.
	SourceID string `json:"sourceId"`
	// The target unique identifier for a Facebook Profile, bigger one will be
	// target.
	TargetID string `json:"targetId"`
}

// NewFacebookFriends creates a new FacebookFriends struct with default values
func NewFacebookFriends() *FacebookFriends {
	return &FacebookFriends{}
}

// Validate validates the FacebookFriends struct
func (f *FacebookFriends) Validate() error {
	return govalidator.NewMulti(govalidator.MinLength(f.SourceID, 1),
		govalidator.MinLength(f.TargetID, 1)).Validate()
}
