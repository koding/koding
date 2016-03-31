package errs

import "errors"

var (
	ErrFacebookProfileFirstNameNotSet  = errors.New("FacebookProfile.FirstName not set")
	ErrFacebookProfileIDNotSet         = errors.New("FacebookProfile.ID not set")
	ErrFacebookProfileLastNameNotSet   = errors.New("FacebookProfile.LastName not set")
	ErrFacebookProfileMiddleNameNotSet = errors.New("FacebookProfile.MiddleName not set")
	ErrFacebookProfilePictureURLNotSet = errors.New("FacebookProfile.PictureURL not set")
)
