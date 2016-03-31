package errs

import "errors"

var (
	ErrProfileCreatedAtNotSet   = errors.New("Profile.CreatedAt not set")
	ErrProfileDeletedAtNotSet   = errors.New("Profile.DeletedAt not set")
	ErrProfileDescriptionNotSet = errors.New("Profile.Description not set")
	ErrProfileIDNotSet          = errors.New("Profile.ID not set")
	ErrProfileLocationNotSet    = errors.New("Profile.Location not set")
	ErrProfileScreenNameNotSet  = errors.New("Profile.ScreenName not set")
	ErrProfileUpdatedAtNotSet   = errors.New("Profile.UpdatedAt not set")
)
