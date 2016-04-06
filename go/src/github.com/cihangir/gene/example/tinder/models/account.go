// Package models holds generated struct for Account.
package models

import (
	"time"

	"github.com/cihangir/govalidator"
)

// AccountEmailStatusConstant holds the predefined enums
var AccountEmailStatusConstant = struct {
	Verified    string
	NotVerified string
}{
	Verified:    "verified",
	NotVerified: "notVerified",
}

// AccountStatusConstant holds the predefined enums
var AccountStatusConstant = struct {
	Registered string
	Disabled   string
	Spam       string
}{
	Registered: "registered",
	Disabled:   "disabled",
	Spam:       "spam",
}

// Account represents a registered User
type Account struct {
	// The unique identifier for a Account
	ID int64 `json:"id,omitempty,string"`
	// The unique identifier for a Account's Profile
	ProfileID int64 `json:"profileId,string"`
	// Unique ID for facebook.com
	FacebookID string `json:"facebookId"`
	// Access token for facebook.com
	FacebookAccessToken string `json:"facebookAccessToken"`
	// Secret token for facebook.com
	FacebookSecretToken string `json:"facebookSecretToken"`
	// Email Address of the Account
	EmailAddress string `json:"emailAddress"`
	// Status of the Account's Email
	EmailStatusConstant string `json:"emailStatusConstant"`
	// Status of the Account
	StatusConstant string `json:"statusConstant,omitempty"`
	// Account's creation time
	CreatedAt time.Time `json:"createdAt,omitempty"`
	// Account's last update time
	UpdatedAt time.Time `json:"updatedAt,omitempty"`
	// Account's deletion time
	DeletedAt time.Time `json:"deletedAt,omitempty"`
}

// NewAccount creates a new Account struct with default values
func NewAccount() *Account {
	return &Account{
		CreatedAt:           time.Now().UTC(),
		EmailStatusConstant: AccountEmailStatusConstant.NotVerified,
		StatusConstant:      AccountStatusConstant.Registered,
		UpdatedAt:           time.Now().UTC(),
	}
}

// Validate validates the Account struct
func (a *Account) Validate() error {
	return govalidator.NewMulti(govalidator.Date(a.CreatedAt),
		govalidator.Date(a.DeletedAt),
		govalidator.Date(a.UpdatedAt),
		govalidator.Min(float64(a.ID), 1.000000),
		govalidator.Min(float64(a.ProfileID), 1.000000),
		govalidator.MinLength(a.FacebookAccessToken, 1),
		govalidator.MinLength(a.FacebookID, 1),
		govalidator.MinLength(a.FacebookSecretToken, 1),
		govalidator.OneOf(a.EmailStatusConstant, []string{
			AccountEmailStatusConstant.Verified,
			AccountEmailStatusConstant.NotVerified,
		}),
		govalidator.OneOf(a.StatusConstant, []string{
			AccountStatusConstant.Registered,
			AccountStatusConstant.Disabled,
			AccountStatusConstant.Spam,
		})).Validate()
}
