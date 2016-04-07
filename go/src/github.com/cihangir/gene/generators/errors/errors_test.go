package errors

import (
	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
)

func TestErrors(t *testing.T) {
	common.RunTest(t, &Generator{}, testdata.JSON1, expecteds)
}

var expecteds = []string{`package errs

var (
	ErrAccountCreatedAtNotSet              = errors.New("Account.CreatedAt not set")
	ErrAccountEmailAddressNotSet           = errors.New("Account.EmailAddress not set")
	ErrAccountEmailStatusConstantNotSet    = errors.New("Account.EmailStatusConstant not set")
	ErrAccountIDNotSet                     = errors.New("Account.ID not set")
	ErrAccountPasswordNotSet               = errors.New("Account.Password not set")
	ErrAccountPasswordStatusConstantNotSet = errors.New("Account.PasswordStatusConstant not set")
	ErrAccountProfileIDNotSet              = errors.New("Account.ProfileID not set")
	ErrAccountSaltNotSet                   = errors.New("Account.Salt not set")
	ErrAccountStatusConstantNotSet         = errors.New("Account.StatusConstant not set")
	ErrAccountURLNotSet                    = errors.New("Account.URL not set")
	ErrAccountURLNameNotSet                = errors.New("Account.URLName not set")
)
`,
	`package errs

var (
	ErrProfileAvatarURLNotSet = errors.New("Profile.AvatarURL not set")
	ErrProfileCreatedAtNotSet = errors.New("Profile.CreatedAt not set")
	ErrProfileFirstNameNotSet = errors.New("Profile.FirstName not set")
	ErrProfileIDNotSet        = errors.New("Profile.ID not set")
	ErrProfileLastNameNotSet  = errors.New("Profile.LastName not set")
	ErrProfileNickNotSet      = errors.New("Profile.Nick not set")
)
`,
}
