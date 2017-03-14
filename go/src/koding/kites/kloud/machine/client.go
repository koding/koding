package machine

import "time"

// Machine represents a single machine.
type Machine struct {
	ID          string    `json:"id"`
	Team        string    `json:"team"`
	Stack       string    `json:"stack"`
	Provider    string    `json:"provider"`
	Label       string    `json:"label"`
	IP          string    `json:"ip"`
	QueryString string    `json:"queryString"`
	RegisterURL string    `json:"registerUrl"`
	CreatedAt   time.Time `json:"createdAt"`
	Status      Status    `json:"status"`
	Users       []User    `json:"users"`
}

// Status represents the current status of machine.
type Status struct {
	State      string    `json:"state"`
	Reason     string    `json:"reason"`
	ModifiedAt time.Time `json:"modifiedAt"`
}

// User represents a single user of described machine.
type User struct {
	Sudo      bool   `json:"sudo"`
	Owner     bool   `json:"owner"`
	Permanent bool   `json:"permanent"`
	Approved  bool   `json:"approved"`
	Username  string `json:"username"`
}

// Filter is used for filtering machine records.
type Filter struct {
	ID           string // machine ID
	Username     string // user name.
	Owners       bool   // keep machine owners.
	OnlyApproved bool   // only approved machines.
}

// Database abstracts database read access to the machines.
type Database interface {
	// Machines returns all machines stored in database that matches a given
	// filter.
	Machines(*Filter) ([]*Machine, error)
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

// Machines returns all machines stored in database that matches a given filter.
func (c *Client) Machines(f *Filter) ([]*Machine, error) {
	return c.db.Machines(f)
}
