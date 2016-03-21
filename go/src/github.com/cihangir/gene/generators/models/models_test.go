package models

import (
	"encoding/json"
	"strings"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/generators/models/validators"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
)

func TestGenerateModel(t *testing.T) {
	var s schema.Schema
	err := json.Unmarshal([]byte(testdata.JSON1), &s)
	common.TestEquals(t, nil, err)

	_, err = GenerateModel(&s)
	common.TestEquals(t, nil, err)
}

func TestGenerateSchema(t *testing.T) {
	s := &schema.Schema{}
	err := json.Unmarshal([]byte(testdata.JSON1), s)
	common.TestEquals(t, nil, err)

	// replace "~" with "`"
	result := strings.Replace(`
// Account represents a registered User
type Account struct {
	// Profile's creation time
	CreatedAt time.Time ~json:"createdAt,omitempty"~
	// Email Address of the Account
	EmailAddress string ~json:"emailAddress"~
	// Status of the Account's Email
	EmailStatusConstant string ~json:"emailStatusConstant,omitempty"~
	// The unique identifier for a Account's Profile
	ID int64 ~json:"id,omitempty,string"~
	// Salted Password of the Account
	Password string ~json:"password"~
	// Status of the Account's Password
	PasswordStatusConstant string ~json:"passwordStatusConstant,omitempty"~
	// The unique identifier for a Account's Profile
	ProfileID int64 ~json:"profileId,omitempty,string"~
	// Salt used to hash Password of the Account
	Salt string ~json:"salt,omitempty"~
	// Status of the Account
	StatusConstant string ~json:"statusConstant,omitempty"~
	// Salted Password of the Account
	URL string ~json:"url,omitempty"~
	// Salted Password of the Account
	URLName string ~json:"urlName,omitempty"~
}`, "~", "`", -1)

	code, err := GenerateSchema(s.Definitions["Account"])
	common.TestEquals(t, nil, err)
	common.TestEquals(t, result, string(code))
}

func TestGenerateValidators(t *testing.T) {
	s := &schema.Schema{}
	err := json.Unmarshal([]byte(testdata.JSON1), s)
	common.TestEquals(t, nil, err)

	result := `
// Validate validates the Account struct
func (a *Account) Validate() error {
	return govalidator.NewMulti(govalidator.Date(a.CreatedAt),
		govalidator.MaxLength(a.Salt, 255),
		govalidator.Min(float64(a.ID), 1.000000),
		govalidator.Min(float64(a.ProfileID), 1.000000),
		govalidator.MinLength(a.Password, 6),
		govalidator.MinLength(a.URL, 6),
		govalidator.MinLength(a.URLName, 6),
		govalidator.OneOf(a.EmailStatusConstant, []string{
			AccountEmailStatusConstant.Verified,
			AccountEmailStatusConstant.NotVerified,
		}),
		govalidator.OneOf(a.PasswordStatusConstant, []string{
			AccountPasswordStatusConstant.Valid,
			AccountPasswordStatusConstant.NeedsReset,
			AccountPasswordStatusConstant.Generated,
		}),
		govalidator.OneOf(a.StatusConstant, []string{
			AccountStatusConstant.Registered,
			AccountStatusConstant.Unregistered,
			AccountStatusConstant.NeedsManualVerification,
		})).Validate()
}`

	code, err := validators.Generate(s.Definitions["Account"])
	common.TestEquals(t, nil, err)
	common.TestEquals(t, result, string(code))
}
