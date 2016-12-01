package team

// Team represents a single team.
type Team struct {
	Name         string `json:"Name"`         // Team name.
	Slug         string `json:"slug"`         // Team slug.
	Members      string `json:"members"`      // Number of team members.
	Privacy      string `json:"privacy"`      // Whether team is public or private.
	Subscription string `json:"subscription"` // Subscription status.
}

// Filter is used for filtering team records.
type Filter struct {
	Username string // user name.
	Teamname string // limit response to a given team name.
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
