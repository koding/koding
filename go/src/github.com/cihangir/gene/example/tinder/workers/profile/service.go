package profile

import (
	"github.com/cihangir/gene/example/tinder/models"
	"golang.org/x/net/context"
)

type profile struct{}

func NewProfile() ProfileService {
	return &profile{}
}

// Create creates a new profile on the system with given profile data.
func (p *profile) Create(ctx context.Context, req *models.Profile) (*models.Profile, error) {
	return nil, nil
}

// Delete deletes the profile from the system with given profile id. Deletes are
// soft.
func (p *profile) Delete(ctx context.Context, req *int64) (*models.Profile, error) {
	return nil, nil
}

// MarkAs marks given account with given type constant, will be used mostly for
// marking as bot.
func (p *profile) MarkAs(ctx context.Context, req *models.MarkAsRequest) (*models.Profile, error) {
	return nil, nil
}

// One returns the respective account with the given ID.
func (p *profile) One(ctx context.Context, req *int64) (*models.Profile, error) {
	return nil, nil
}

// Update updates a new profile on the system with given profile data.
func (p *profile) Update(ctx context.Context, req *models.Profile) (*models.Profile, error) {
	return nil, nil
}
