package presence

import "time"

// PrivatePing is only used internaly for ping requests
type PrivatePing struct {
	// GroupName holds group name
	GroupName string `json:"groupName"`

	// Username holds the user's nick
	Username string `json:"username"`
}

// Ping holds the ping data
type Ping struct {
	// GroupName holds group name
	GroupName string `json:"groupName"`

	// AccountID holds the host's id the only one that can send this request
	AccountID int64 `json:"accountID,string"`

	// CreatedAt holds the ping time
	CreatedAt time.Time `json:"createdAt"`

	// paymentStatus is populated on handler
	paymentStatus string
}

// NewPing creates an empty ping
func NewPing() *Ping {
	return &Ping{}
}

// GetId returns the id of the ping, it is here just to satisfy Bongo.Modellable
// interface
func (a Ping) GetId() int64 {
	return 0
}

// BongoName returns the unique name for the bongo operations
func (a Ping) BongoName() string {
	return "presence.ping"
}
