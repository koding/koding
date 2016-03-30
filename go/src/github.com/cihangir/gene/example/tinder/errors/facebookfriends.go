package errs

import "errors"

var (
	ErrFacebookFriendsSourceIDNotSet = errors.New("FacebookFriends.SourceID not set")
	ErrFacebookFriendsTargetIDNotSet = errors.New("FacebookFriends.TargetID not set")
)
