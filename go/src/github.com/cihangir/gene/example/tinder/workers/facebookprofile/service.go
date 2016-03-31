package facebookprofile

import (
	"github.com/cihangir/gene/example/tinder/models"
	"golang.org/x/net/context"
)

type facebookprofile struct{}

func NewFacebookProfile() FacebookProfileService {
	return &facebookprofile{}
}

// ByIDs fetches multiple FacebookProfile from system by their IDs
func (f *facebookprofile) ByIDs(ctx context.Context, req *[]string) (*[]*models.FacebookProfile, error) {
	return nil, nil
}

// Create persists a FacebookProfile in the system
func (f *facebookprofile) Create(ctx context.Context, req *models.FacebookProfile) (*models.FacebookProfile, error) {
	return nil, nil
}

// One fetches an FacebookProfile from system by its ID
func (f *facebookprofile) One(ctx context.Context, req *int64) (*models.FacebookProfile, error) {
	return nil, nil
}

// Update updates the FacebookProfile on the system with given FacebookProfile
// data.
func (f *facebookprofile) Update(ctx context.Context, req *models.FacebookProfile) (*models.FacebookProfile, error) {
	return nil, nil
}
