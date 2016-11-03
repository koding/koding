package machine

import "time"

// Machine represents a single machine.
type Machine struct {
	Team     string        `json:"team"`
	IP       string        `json:"ip"`
	Provider string        `json:"provider"`
	Label    string        `json:"label"`
	Status   MachineStatus `json:"status"`
}

// MachineStatus represents current status of machine.
type MachineStatus struct {
	State      string    `json:"state"`
	Reason     string    `json:"reason"`
	ModifiedAt time.Time `json:"modifiedAt"`
}

// Filter is used for filtering machine records.
type Filter struct {
	Username string // user name
}

// Database abstracts database read access to the machines.
type Database interface {
	// Machines returns all machines stored in database that matches a given
	// filter.
	Machines(*Filter) ([]*Machine, error)
}

type Client struct {
	db Database
}

func NewClient(db Database) *Client {
	return &Client{
		db: db,
	}
}

// Machines returns all machines stored in database that matches a given filter.
func (c *Client) Machines(f *Filter) ([]*Machine, error) {
	return c.db.Machines(f)
}
