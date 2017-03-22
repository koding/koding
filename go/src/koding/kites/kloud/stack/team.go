package stack

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/team"

	"github.com/koding/kite"
)

// TeamListRequest represents a request type for "team.list" kloud's
// kite method.
type TeamListRequest struct {
	// Slug is a filter for team name. If empty, all available teams for a
	// given user will be returned.
	Slug string `json:"slug"`
}

// TeamListResponse represents a response model for "team.list" kloud's
// kite method.
type TeamListResponse struct {
	Teams []*team.Team `json:"teams"`
}

// TeamList is a kite.Handler for "team.list" kite method.
func (k *Kloud) TeamList(r *kite.Request) (interface{}, error) {
	var req TeamListRequest
	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	f := &team.Filter{
		Username: r.Username,
		Slug:     req.Slug,
	}

	teams, err := k.TeamClient.Teams(f)
	if err != nil {
		return nil, err
	}

	return TeamListResponse{Teams: teams}, nil
}

// WhoamiResponse represents a response value for a "team.whoami" kite method.
type WhoamiResponse struct {
	Team *team.Team `json:"team"`
}

// TestWhoami is a kite handler for a "team.whoami" kite method.
func (k *Kloud) TeamWhoami(r *kite.Request) (interface{}, error) {
	opts := &modelhelper.LookupGroupOptions{
		Username:    r.Username,
		KiteID:      r.Client.ID,
		ClientURL:   r.Client.URL,
		Environment: r.Client.Environment,
	}

	group, err := modelhelper.LookupGroup(opts)
	if err != nil {
		return nil, models.ResError(err, "jGroup")
	}

	return &WhoamiResponse{
		Team: &team.Team{
			Name:      group.Title,
			Slug:      group.Slug,
			Privacy:   group.Privacy,
			SubStatus: group.Payment.Subscription.Status,
			Paid:      group.IsSubActive(k.Environment),
		},
	}, nil
}
