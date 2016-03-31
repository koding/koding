// Generated struct for Profile.
package models

import (
	"time"

	"github.com/cihangir/govalidator"
)

// Profile represents a registered Account's Public Info
type Profile struct {
	// The unique identifier for a Account's Profile
	ID int64 `json:"id,omitempty,string"`
	// Full name associated with the profile. Maximum of 20 characters.
	ScreenName string `json:"screenName"`
	// The city or country describing where the user of the account is located. The
	// contents are not normalized or geocoded in any way. Maximum of 30 characters.
	Location string `json:"location,omitempty"`
	// A description of the user owning the account. Maximum of 160 characters.
	Description string `json:"description,omitempty"`
	// Profile's creation time
	CreatedAt time.Time `json:"createdAt,omitempty"`
	// Profile's last update time
	UpdatedAt time.Time `json:"updatedAt,omitempty"`
	// Profile's deletion time
	DeletedAt time.Time `json:"deletedAt,omitempty"`
}

// NewProfile creates a new Profile struct with default values
func NewProfile() *Profile {
	return &Profile{
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}
}

// Validate validates the Profile struct
func (p *Profile) Validate() error {
	return govalidator.NewMulti(govalidator.Date(p.CreatedAt),
		govalidator.Date(p.DeletedAt),
		govalidator.Date(p.UpdatedAt),
		govalidator.MaxLength(p.Description, 160),
		govalidator.MaxLength(p.Location, 30),
		govalidator.MaxLength(p.ScreenName, 20),
		govalidator.Min(float64(p.ID), 1.000000),
		govalidator.MinLength(p.ScreenName, 4)).Validate()
}
