package errs

import "errors"

var (
	ErrAccountCreatedAtNotSet           = errors.New("Account.CreatedAt not set")
	ErrAccountDeletedAtNotSet           = errors.New("Account.DeletedAt not set")
	ErrAccountEmailAddressNotSet        = errors.New("Account.EmailAddress not set")
	ErrAccountEmailStatusConstantNotSet = errors.New("Account.EmailStatusConstant not set")
	ErrAccountFacebookAccessTokenNotSet = errors.New("Account.FacebookAccessToken not set")
	ErrAccountFacebookIDNotSet          = errors.New("Account.FacebookID not set")
	ErrAccountFacebookSecretTokenNotSet = errors.New("Account.FacebookSecretToken not set")
	ErrAccountIDNotSet                  = errors.New("Account.ID not set")
	ErrAccountProfileIDNotSet           = errors.New("Account.ProfileID not set")
	ErrAccountStatusConstantNotSet      = errors.New("Account.StatusConstant not set")
	ErrAccountUpdatedAtNotSet           = errors.New("Account.UpdatedAt not set")
)
