package facebookfriends

import (
	"github.com/cihangir/gene/example/tinder/models"
	"golang.org/x/net/context"
)

const ServiceName = "facebookfriends"

// Holds Facebook Friendship Status
type FacebookFriendsService interface {
	// Create creates a relationship between two facebook account. This function is
	// idempotent
	Create(ctx context.Context, req *models.FacebookFriends) (res *models.FacebookFriends, err error)

	// Delete removes friendship.
	Delete(ctx context.Context, req *models.FacebookFriends) (res *models.FacebookFriends, err error)

	// Mutuals return mutual friend's Facebook IDs between given source id and
	// target id. Source and Target are inclusive.
	Mutuals(ctx context.Context, req *[]*models.FacebookFriends) (res *[]string, err error)

	// One fetches a FacebookFriends from system with FacebookFriends, will be used
	// for validating the existance of the friendship
	One(ctx context.Context, req *models.FacebookFriends) (res *models.FacebookFriends, err error)
}
