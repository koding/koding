package facebookprofile

import (
	"github.com/cihangir/gene/example/tinder/models"
	"golang.org/x/net/context"
)

const ServiceName = "facebookprofile"

// Holds Facebook Profiles
type FacebookProfileService interface {
	// ByIDs fetches multiple FacebookProfile from system by their IDs
	ByIDs(ctx context.Context, req *[]string) (res *[]*models.FacebookProfile, err error)

	// Create persists a FacebookProfile in the system
	Create(ctx context.Context, req *models.FacebookProfile) (res *models.FacebookProfile, err error)

	// One fetches an FacebookProfile from system by its ID
	One(ctx context.Context, req *int64) (res *models.FacebookProfile, err error)

	// Update updates the FacebookProfile on the system with given FacebookProfile
	// data.
	Update(ctx context.Context, req *models.FacebookProfile) (res *models.FacebookProfile, err error)
}
