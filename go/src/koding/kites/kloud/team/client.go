package team

import "koding/db/models"

// Team represents a single team.
type Team struct {
	Name      string           `json:"name"`         // Team name.
	Slug      string           `json:"slug"`         // Team slug.
	Privacy   string           `json:"privacy"`      // Whether team is public or private.
	SubStatus models.SubStatus `json:"subscription"` // Subscription status; deprecated - use Paid field instead.
	Paid      bool             `json:"paid"`         // Whether team subscription is paid.
}

// IsSubActive checks if Team's sub is in active state.
func (t *Team) IsSubActive(env string) bool {
	return models.IsSubActive(env, t.SubStatus)
}

// Filter is used for filtering team records.
type Filter struct {
	Username string // user name.
	Slug     string // limit response to a given group name.
}

// Database abstracts database read access to the machines.
type Database interface {
	// Teams returns all teams stored in database that matches a given filter.
	Teams(*Filter) ([]*Team, error)
}

// Client enables communication with machine related logic.
type Client struct {
	db Database
}

// NewClient creates a new Client instance.
func NewClient(db Database) *Client {
	return &Client{
		db: db,
	}
}

// Teams returns all teams stored in database that matches a given filter.
func (c *Client) Teams(f *Filter) ([]*Team, error) {
	return c.db.Teams(f)
}
