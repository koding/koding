package profile

import (
	"github.com/cihangir/gene/example/tinder/models"
	"golang.org/x/net/context"
)

const ServiceName = "profile"

// Profile represents a registered Account's Public Info
type ProfileService interface {
	// Create creates a new profile on the system with given profile data.
	Create(ctx context.Context, req *models.Profile) (res *models.Profile, err error)

	// Delete deletes the profile from the system with given profile id. Deletes are
	// soft.
	Delete(ctx context.Context, req *int64) (res *models.Profile, err error)

	// MarkAs marks given account with given type constant, will be used mostly for
	// marking as bot.
	MarkAs(ctx context.Context, req *models.MarkAsRequest) (res *models.Profile, err error)

	// One returns the respective account with the given ID.
	One(ctx context.Context, req *int64) (res *models.Profile, err error)

	// Update updates a new profile on the system with given profile data.
	Update(ctx context.Context, req *models.Profile) (res *models.Profile, err error)
}
