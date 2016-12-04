package stack

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"github.com/koding/kite"
)

// Team represents a user's team.
//
// TODO(rjeczalik): replace with team.Team
type Team struct {
	Name         string `json:"name"`
	Title        string `json:"title"`
	Subscription string `json:"subscription,omitempty"`
}

// WhoamiResponse represents a response value for a "team.whoami" kite method.
type WhoamiResponse struct {
	Team *Team `json:"team"`
}

// TestWhoami is a kite handler for a "team.whoami" kite method.
func (k *Kloud) TeamWhoami(r *kite.Request) (interface{}, error) {
	group, err := modelhelper.GetGroupForKite(r.Client.ID)
	if err != nil {
		return nil, models.ResError(err, "jGroup")
	}

	return &WhoamiResponse{
		Team: &Team{
			Name:         group.Slug,
			Title:        group.Title,
			Subscription: group.Payment.Subscription.Status,
		},
	}, nil
}
