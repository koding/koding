package stack

import (
	"koding/kites/kloud/team"

	"github.com/koding/kite"
)

// TeamListRequest represents a request type for "team.list" kloud's
// kite method.
type TeamListRequest struct {
	// TeamName is a filter for team name. If empty, all available teams for a
	// given user will be returned.
	Team string `json:"team"`
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
		Teamname: req.Team,
	}

	teams, err := k.TeamClient.Teams(f)
	if err != nil {
		return nil, err
	}

	return TeamListResponse{Teams: teams}, nil
}
