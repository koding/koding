package facebookfriends

import (
	"github.com/cihangir/gene/example/tinder/models"
	"golang.org/x/net/context"
)

type facebookfriends struct{}

func NewFacebookFriends() FacebookFriendsService {
	return &facebookfriends{}
}

// Create creates a relationship between two facebook account. This function is
// idempotent
func (f *facebookfriends) Create(ctx context.Context, req *models.FacebookFriends) (*models.FacebookFriends, error) {
	return nil, nil
}

// Delete removes friendship.
func (f *facebookfriends) Delete(ctx context.Context, req *models.FacebookFriends) (*models.FacebookFriends, error) {
	return nil, nil
}

// Mutuals return mutual friend's Facebook IDs between given source id and
// target id. Source and Target are inclusive.
func (f *facebookfriends) Mutuals(ctx context.Context, req *[]*models.FacebookFriends) (*[]string, error) {
	return nil, nil
}

// One fetches a FacebookFriends from system with FacebookFriends, will be used
// for validating the existance of the friendship
func (f *facebookfriends) One(ctx context.Context, req *models.FacebookFriends) (*models.FacebookFriends, error) {
	return nil, nil
}
